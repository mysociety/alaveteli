require 'English'
require 'fileutils'

##
# Drives a search reindex from the command line.
#
# `reindex:all` and `reindex:missing` do not load the app. They spawn a
# fresh `reindex:chunk` process per chunk, so the memory a chunk needs goes
# back to the OS when its process exits rather than piling up over a run of
# millions of records. Each worker indexes one chunk, writes down how far it
# got, and exits.
#
module ReindexTask
  module_function

  # exit status a worker uses to say it indexed a chunk and there is
  # probably more to do. 0 means nothing was left, and anything else is a
  # genuine failure.
  CHUNK_PROCESSED = 10

  # what a model's state file holds once it has been worked through
  DONE = 'done'.freeze

  # Spawn workers until one of them reports there is nothing left to do.
  def coordinate(names, only_missing:)
    # state from an earlier run is only picked up when resuming
    FileUtils.rm_rf(state_dir) if ENV['RESET']

    env = { 'ONLY_MISSING' => only_missing ? '1' : '0' }
    env['MODELS'] = names if names

    loop do
      system(env, 'bin/rake', 'reindex:chunk')
      status = $CHILD_STATUS.exitstatus

      case status
      when 0 then break
      when CHUNK_PROCESSED then next
      else abort "reindex:chunk failed (exit #{status.inspect})"
      end
    end

    puts 'Reindex complete'
  end

  # Index one chunk, then exit so the OS takes back everything this process
  # allocated.
  def chunk
    # every `searchable` declaration has to have run for the list to be whole
    Rails.application.eager_load!

    # a reindex issues an upsert per record, and in development ActiveRecord
    # logs every one of them, which dominates the disk IO
    ActiveRecord::Base.logger&.level = Logger::WARN

    models.each do |model|
      next if finished?(model)

      count = index_chunk_of(model)

      # a model built inside the database is done by one statement, and a
      # chunk that came up short has reached the end of its model
      finish(model) if model.reindex_inside_db? || count < chunk_size
      next if count.zero?

      puts "Indexed #{count} #{model} records"
      exit(CHUNK_PROCESSED)
    end

    exit(0)
  end

  def index_chunk_of(model)
    last_id = cursor(model)
    model.reindex_all(
      start_id: last_id && last_id + 1,
      only_missing: ENV['ONLY_MISSING'] != '0',
      limit: chunk_size,
      batch_size: batch_size
    ) { |id| record_cursor(model, id) }
  end

  # The models to work through. Set MODELS to a comma separated list to
  # limit the run to some of them.
  def models
    names = ENV['MODELS']
    return Searchable.models unless names

    names.split(',').map { |name| name.strip.constantize }
  end

  def chunk_size
    Integer(ENV['CHUNK_SIZE'] || 10_000)
  end

  def batch_size
    Integer(ENV['BATCH_SIZE'] || 1_000)
  end

  # The last id an earlier chunk indexed, or nil to start at the beginning.
  def cursor(model)
    state = read_state(model)
    state.to_i unless state.nil? || state == DONE
  end

  def record_cursor(model, id)
    write_state(model, id.to_s)
  end

  # Whether an earlier chunk worked the model through to the end.
  def finished?(model)
    read_state(model) == DONE
  end

  def finish(model)
    write_state(model, DONE)
  end

  def state_dir
    File.join(Dir.pwd, 'tmp', 'reindex')
  end

  def state_file(model)
    File.join(state_dir, "#{model.name.tr(':', '_')}.state")
  end

  def read_state(model)
    file = state_file(model)
    File.read(file) if File.exist?(file)
  end

  def write_state(model, value)
    FileUtils.mkdir_p(state_dir)
    File.write(state_file(model), value)
  end
end

namespace :reindex do
  desc "Reindex events in batches"
  task events: :environment do
    reindex_log = Logger.new("#{Rails.root}/log/reindex_events.log")
    last_id = ENV["LAST_EVENT_ID"] || 0
    batch_size = (ENV["BATCH_SIZE"] || 300).to_i # default to 300
    sleep_time = (ENV["SLEEP_TIME"] || 300).to_i # default to 5 minutes

    reindex_log.info("run started... #{Time.now}")

    current_id = 0 # keep track of the current event
    begin
      InfoRequestEvent.where("id > #{last_id}").find_in_batches(batch_size: batch_size) do |events|
        events.each do |event|
          current_id = event.id
          Search.reindex_later(event)
          last_id = event.id
        end
        reindex_log.info("* queued batch ending: #{events.last.id}")
        # wait so that the next batch gets collected by the next indexing run
        sleep sleep_time
      end
      reindex_log.info("reindex queuing complete!")
    rescue Exception => e
      reindex_log.error("** Error while processing event #{current_id}, " \
                        "last event successfully queued was: #{last_id}")
      reindex_log.error("uncaught #{e} exception while handling connection: #{e.message}")
      reindex_log.error("Stack trace: #{e.backtrace.map { |l| "  #{l}\n" }.join}")
      abort
    end
  end

  desc "Reindex public bodies in batches"
  task public_bodies: :environment do
    reindex_log = Logger.new("#{Rails.root}/log/reindex_public_bodies.log")
    last_id = ENV["LAST_PUBLIC_BODY_ID"] || 0
    batch_size = (ENV["BATCH_SIZE"] || 300).to_i # default to 300
    sleep_time = (ENV["SLEEP_TIME"] || 300).to_i # default to 5 minutes

    reindex_log.info("run started... #{Time.now}")

    current_id = 0 # keep track of the current public body
    begin
      PublicBody.where("id > #{last_id}").find_in_batches(batch_size: batch_size) do |bodies|
        bodies.each do |body|
          current_id = body.id
          Search.reindex_later(body)
          last_id = body.id
        end
        reindex_log.info("* queued batch ending: #{bodies.last.id}")
        # wait so that the next batch gets collected by the next indexing run
        sleep sleep_time
      end
      reindex_log.info("reindex queuing complete!")
    rescue Exception => e
      reindex_log.error("** Error while processing body #{current_id}, " \
                        "last body successfully queued was: #{last_id}")
      reindex_log.error("uncaught #{e} exception while handling connection: #{e.message}")
      reindex_log.error("Stack trace: #{e.backtrace.map { |l| "  #{l}\n" }.join}")
      abort
    end
  end

  desc "Reindex users in batches"
  task users: :environment do
    reindex_log = Logger.new("#{Rails.root}/log/reindex_users.log")
    last_id = ENV["LAST_USER_ID"] || 0
    batch_size = (ENV["BATCH_SIZE"] || 300).to_i # default to 300
    sleep_time = (ENV["SLEEP_TIME"] || 300).to_i # default to 5 minutes

    reindex_log.info("run started... #{Time.now}")

    current_id = 0 # keep track of the current user
    begin
      User.where("id > #{last_id}").find_in_batches(batch_size: batch_size) do |users|
        users.each do |user|
          current_id = user.id
          Search.reindex_later(user)
          last_id = user.id
        end
        reindex_log.info("* queued batch ending: #{users.last.id}")
        # wait so that the next batch gets collected by the next indexing run
        sleep sleep_time
      end
      reindex_log.info("reindex queuing complete!")
    rescue Exception => e
      reindex_log.error("** Error while processing user #{current_id}, " \
                        "last user successfully queued was: #{last_id}")
      reindex_log.error("uncaught #{e} exception while handling connection: #{e.message}")
      reindex_log.error("Stack trace: #{e.backtrace.map { |l| "  #{l}\n" }.join}")
      abort
    end
  end
end

namespace :reindex do
  desc 'Reindex searchable records, or those of MODEL'
  task :all, [:model] do |_task, args|
    ReindexTask.coordinate(args[:model], only_missing: false)
  end

  desc 'Index searchable records that have no search document yet'
  task :missing, [:model] do |_task, args|
    ReindexTask.coordinate(args[:model], only_missing: true)
  end

  desc 'Index one chunk of records then exit, spawned by the tasks above'
  task chunk: :environment do
    ReindexTask.chunk
  end
end

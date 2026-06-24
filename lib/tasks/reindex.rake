require "English"
require "fileutils"

namespace :reindex do
  # exit status used by `reindex:chunk` to tell the `reindex:missing`
  # coordinator that it indexed a chunk and more work probably remains. 0 means
  # nothing was left to index; anything else is a genuine failure.
  CHUNK_PROCESSED = 10

  # Index one chunk of records, then exit so the OS reclaims everything this
  # process allocated. Spawned repeatedly by `reindex:missing`/`reindex:all`,
  # which is how memory is released periodically: each chunk runs in a brand new
  # process rather than accumulating in a long-lived one.
  #
  # Progress is tracked with a per-model id cursor file under STATE_DIR so a
  # record that fails to index can't stall the run. Unless ONLY_MISSING is "0"
  # (set by `reindex:all`), `not_indexed` also skips records already indexed by
  # an earlier run, keeping `reindex:missing` resumable and dedup'd.
  task chunk: :environment do
    # ensure every `searchable` declaration has run so all models are known
    Rails.application.eager_load!

    # A full reindex issues an upsert per record; in the default development
    # environment ActiveRecord logs every statement, and those writes dominate
    # disk IO. Quietening the logger keeps the run IO-bound on the real work.
    ActiveRecord::Base.logger&.level = Logger::WARN

    chunk_size = (ENV["CHUNK_SIZE"] || 10_000).to_i
    batch_size = (ENV["BATCH_SIZE"] || 1_000).to_i
    only_missing = ENV["ONLY_MISSING"] != "0"
    state_dir = ENV.fetch("STATE_DIR") { File.join(Dir.pwd, "tmp", "reindex") }
    FileUtils.mkdir_p(state_dir)

    models =
      if ENV["MODELS"].present?
        ENV["MODELS"].split(",").map { |name| name.strip.constantize }
      else
        Searchable.searchable_models
      end

    models.each do |model|
      cursor_file = File.join(state_dir, "#{model.name.tr(':', '_')}.cursor")
      last_id = File.exist?(cursor_file) ? File.read(cursor_file).to_i : 0
      pk = "#{model.quoted_table_name}.#{model.quoted_primary_key}"

      scope = model.indexable
      scope = scope.not_indexed if only_missing
      ids = scope.
        where("#{pk} > ?", last_id).
        order(model.primary_key).
        limit(chunk_size).
        pluck(model.primary_key)
      next if ids.empty?

      records = model.indexable.where(id: ids)
      records.find_each(batch_size: batch_size) do |record|
        model.reindex_record(record)
      end

      File.write(cursor_file, ids.max.to_s)
      puts "Indexed #{ids.size} #{model} records (up to id #{ids.max})"
      exit(CHUNK_PROCESSED)
    end

    # no model had records left to index
    exit(0)
  end

  # Drive a chunked reindex by spawning a fresh `reindex:chunk` process per
  # chunk until one reports there is nothing left to do. Deliberately avoids
  # loading the app itself, so this coordinator stays tiny while memory is
  # released between chunks by the short-lived workers.
  def coordinate_reindex(model_arg, only_missing:)
    state_dir = ENV["STATE_DIR"] || File.join(Dir.pwd, "tmp", "reindex")

    # discard cursors from a previous run unless explicitly resuming
    FileUtils.rm_rf(state_dir) unless ENV["RESUME"]

    env = {
      "STATE_DIR" => state_dir,
      "ONLY_MISSING" => only_missing ? "1" : "0"
    }
    env["MODELS"] = model_arg if model_arg.present?
    %w[CHUNK_SIZE BATCH_SIZE].each { |key| env[key] = ENV[key] if ENV[key] }

    loop do
      system(env, "bundle", "exec", "rake", "reindex:chunk")
      status = $CHILD_STATUS.exitstatus
      case status
      when 0 then break
      when CHUNK_PROCESSED then next
      else abort "reindex:chunk failed (exit #{status.inspect})"
      end
    end

    puts "Reindex complete"
  end

  desc "Index searchable records missing a search document (resumable, dedup)"
  task :missing, [:model] do |_task, args|
    coordinate_reindex(args[:model], only_missing: true)
  end

  desc "Reindex every searchable record (full rebuild, resumable)"
  task :all, [:model] do |_task, args|
    coordinate_reindex(args[:model], only_missing: false)
  end

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

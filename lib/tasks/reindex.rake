require "English"
require "fileutils"
require "ruby-progressbar"

namespace :reindex do
  CHUNK_PROCESSED = 10 # exit status to tell coordinator more work remains

  task chunk: :environment do
    # ensure every `searchable` declaration has run so all models are known
    Rails.application.eager_load!

    ActiveRecord::Base.logger&.level = Logger::WARN

    chunk_size = (ENV["CHUNK_SIZE"] || 10_000).to_i
    batch_size = (ENV["BATCH_SIZE"] || 1_000).to_i
    record_timeout = (ENV["RECORD_TIMEOUT"] || 30).to_i
    only_missing = ENV["ONLY_MISSING"] != "0"
    state_dir = ENV.fetch("STATE_DIR") { File.join(Dir.pwd, "tmp", "reindex") }
    FileUtils.mkdir_p(state_dir)

    # Wall-clock start of the whole run, recorded once and shared by every
    # chunk process so the ETA can be based on the overall rate rather than a
    # single short-lived chunk.
    started_file = File.join(state_dir, "started_at")
    unless File.exist?(started_file)
      File.write(started_file, Time.now.to_f.to_s)
    end
    started_at = File.read(started_file).to_f

    # Records that error or time out are recorded here so later chunks and
    # later runs skip them instead of stalling on them again. This dir is
    # deliberately separate from STATE_DIR, which the coordinator wipes
    # between runs, so the skip list survives a fresh reindex.
    skip_dir = ENV.fetch("SKIP_DIR") do
      File.join(Dir.pwd, "tmp", "reindex_skipped")
    end
    FileUtils.mkdir_p(skip_dir)

    models =
      if ENV["MODELS"].present?
        ENV["MODELS"].split(",").map { |name| name.strip.constantize }
      else
        Searchable.searchable_models
      end

    models.each do |model|
      slug = model.name.tr(":", "_")
      cursor_file = File.join(state_dir, "#{slug}.cursor")
      skip_file = File.join(skip_dir, "#{slug}.skip")
      last_id = File.exist?(cursor_file) ? File.read(cursor_file).to_i : 0
      skip_ids =
        File.exist?(skip_file) ? File.readlines(skip_file).map(&:to_i) : []
      pk = "#{model.quoted_table_name}.#{model.quoted_primary_key}"

      scope = model.indexable
      scope = scope.not_indexed if only_missing
      scope = scope.where.not(model.primary_key => skip_ids) if skip_ids.any?
      ids = scope.
        where("#{pk} > ?", last_id).
        order(model.primary_key).
        limit(chunk_size).
        pluck(model.primary_key)
      next if ids.empty?

      done_file = File.join(state_dir, "#{slug}.done")
      done = File.exist?(done_file) ? File.read(done_file).to_i : 0
      total = reindex_total(model, only_missing: only_missing,
                                   state_dir: state_dir)
      # The native ETA only sees a single chunk's process, so it resets and
      # misleads every chunk. Compute one from the overall rate instead.
      bar = ProgressBar.create(
        title: reindex_title(model, done: done, total: total,
                                    started_at: started_at),
        total: total,
        starting_at: [done, total].min,
        format: "%t %c/%C (%p%%)",
        output: $stdout
      )

      failed_ids = []
      records = model.indexable.where(id: ids)
      records.find_each(batch_size: batch_size) do |record|
        unless model.reindex_record(record, timeout: record_timeout)
          failed_ids << record.id
        end
        # guard against a cached total drifting below the real count
        bar.increment if bar.progress < bar.total
      end

      File.open(skip_file, "a") do |f|
        failed_ids.each { |id| f.puts(id) }
      end

      File.write(done_file, (done + ids.size).to_s)
      File.write(cursor_file, ids.max.to_s)
      bar.log("Skipped #{failed_ids.size} #{model} records") if failed_ids.any?
      exit(CHUNK_PROCESSED)
    end

    # no model had records left to index
    exit(0)
  end

  # Total number of records a run will index for a model, used to size the
  # progress bar. The count is taken once and cached per model so successive
  # chunk workers reuse it rather than re-running an expensive count.
  def reindex_total(model, only_missing:, state_dir:)
    total_file = File.join(state_dir, "#{model.name.tr(':', '_')}.total")
    return File.read(total_file).to_i if File.exist?(total_file)

    puts "Counting #{model} records to index..."
    scope = model.indexable
    scope = scope.not_indexed if only_missing
    total = scope.count
    File.write(total_file, total.to_s)
    total
  end

  # Progress bar title carrying an ETA derived from the overall rate so far
  # (records done since the run started), which is stable across the separate
  # processes a chunked run spawns. The ETA is omitted until there is progress
  # to extrapolate from.
  def reindex_title(model, done:, total:, started_at:)
    elapsed = Time.now.to_f - started_at
    return model.name unless done.positive? && elapsed.positive?

    rate = done / elapsed
    return model.name unless rate.positive?

    "#{model.name} (ETA #{format_duration((total - done) / rate)})"
  end

  def format_duration(seconds)
    seconds = seconds.round
    format("%02d:%02d:%02d",
           seconds / 3600, (seconds % 3600) / 60, seconds % 60)
  end

  def coordinate_reindex(models, only_missing:)
    state_dir = ENV["STATE_DIR"] || File.join(Dir.pwd, "tmp", "reindex")
    skip_dir = ENV["SKIP_DIR"] || File.join(Dir.pwd, "tmp", "reindex_skipped")

    # discard cursors from a previous run unless explicitly resuming, but keep
    # the skip list so records that already failed are not retried
    FileUtils.rm_rf(state_dir) unless ENV["RESUME"]

    models = Array(models).map(&:to_s).reject(&:empty?)

    env = {
      "STATE_DIR" => state_dir,
      "SKIP_DIR" => skip_dir,
      "ONLY_MISSING" => only_missing ? "1" : "0"
    }
    env["MODELS"] = models.join(",") if models.any?
    %w[CHUNK_SIZE BATCH_SIZE RECORD_TIMEOUT].each do |key|
      env[key] = ENV[key] if ENV[key]
    end

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

  # Models can be passed as task arguments, e.g.
  # rake "reindex:missing[PublicBody,IncomingMessage]", and default to every
  # searchable model when none are given.
  def reindex_model_args(args)
    [args[:model], *args.extras]
  end

  desc "Index searchable records missing a search document (resumable, dedup)"
  task :missing, [:model] do |_task, args|
    coordinate_reindex(reindex_model_args(args), only_missing: true)
  end

  desc "Reindex every searchable record (full rebuild, resumable)"
  task :all, [:model] do |_task, args|
    coordinate_reindex(reindex_model_args(args), only_missing: false)
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

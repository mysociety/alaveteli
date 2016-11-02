# -*- encoding : utf-8 -*-

namespace :reindex do
  desc "Reindex events in batches"
  task :events => :environment do
    reindex_log = Logger.new("#{Rails.root}/log/reindex.log")
    last_id = ENV["LAST_EVENT_ID"] || 0
    batch_size = (ENV["BATCH_SIZE"] || 300).to_i # default to 300
    sleep_time = (ENV["SLEEP_TIME"] || 300).to_i # default to 5 minutes

    reindex_log.info("\nrun started... #{Time.now}")

    current_id = 0 # keep track of the current event
    begin
      InfoRequestEvent.where("id > #{last_id}").find_in_batches(:batch_size => batch_size) do |events|
        events.each do |event|
          current_id = event.id
          event.xapian_mark_needs_index
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
      reindex_log.error("Stack trace: #{e.backtrace.map {|l| "  #{l}\n"}.join}")
      abort
    end
  end
end

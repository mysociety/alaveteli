namespace :cleanup do

  desc 'Clean up old events (> 1 year) from the holding pen to make admin actions there faster'
  task :holding_pen => :environment do
    dryrun = ENV['DRYRUN'] != '0'
    if dryrun
        STDERR.puts "This is a dryrun - nothing will be deleted"
    end
    holding_pen = InfoRequest.find_by_url_title('holding_pen')
    old_events = holding_pen.info_request_events.find_each(:conditions => ['event_type in (?)
                                                                            AND created_at < ?',
                                                      ['redeliver_incoming',
                                                      'destroy_incoming'],
                                                      Time.now - 1.year]) do |event|
      puts event.inspect
      if ! dryrun
        event.destroy
      end
    end
  end

end

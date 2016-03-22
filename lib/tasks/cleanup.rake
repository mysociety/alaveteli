namespace :cleanup do

  desc 'Clean up all message redelivery and destroy actions from the holding pen to make admin actions there faster'
  task :holding_pen => :environment do
    dryrun = ENV['DRYRUN'] != '0' if ENV['DRYRUN']
    if dryrun
      $stderr.puts "This is a dryrun - nothing will be deleted"
    end
    holding_pen = InfoRequest.find_by_url_title('holding_pen')
    old_events = holding_pen.info_request_events.find_each(:conditions => ['event_type in (?)',
                                                      ['redeliver_incoming',
                                                      'destroy_incoming']]) do |event|
      puts event.inspect
      if ! dryrun
        event.destroy
      end
    end
  end

end

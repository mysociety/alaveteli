# -*- encoding : utf-8 -*-
namespace :incoming_messages do
  desc 'Parse unparsed incoming messages belonging to Pro users'
  task parse_unparsed_pro: :environment do
    verbose = ENV.key?('VERBOSE')

    IncomingMessage.unparsed.pro.find_each do |msg|
      bm = Benchmark.measure { msg.parse_raw_email! }
      puts "Parsed #{msg.id} in #{ bm.real.round(6) }" if verbose
    end
  end

  desc 'Update InfoRequest#incoming_messages_count counter cache'
  task update_counter_cache: :environment do
    InfoRequest.update_all('incoming_messages_count = (SELECT COUNT(*) FROM ' \
      '"incoming_messages" WHERE "incoming_messages"."info_request_id" = ' \
      '"info_requests"."id")')
  end
end

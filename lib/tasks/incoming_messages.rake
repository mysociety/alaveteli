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
end

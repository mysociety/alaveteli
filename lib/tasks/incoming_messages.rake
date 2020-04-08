# -*- encoding : utf-8 -*-
namespace :incoming_messages do
  desc 'Update InfoRequest#incoming_messages_count counter cache'
  task update_counter_cache: :environment do
    InfoRequest.update_all('incoming_messages_count = (SELECT COUNT(*) FROM ' \
      '"incoming_messages" WHERE "incoming_messages"."info_request_id" = ' \
      '"info_requests"."id")')
  end
end

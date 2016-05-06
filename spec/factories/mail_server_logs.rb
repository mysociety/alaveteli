# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :mail_server_log do
    info_request
    mail_server_log_done
    sequence(:order) { |n| n }
    line 'log line'
  end

end

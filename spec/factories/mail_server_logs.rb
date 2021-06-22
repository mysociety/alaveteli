# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20210114161442
#
# Table name: mail_server_logs
#
#  id                      :integer          not null, primary key
#  mail_server_log_done_id :integer
#  info_request_id         :integer
#  order                   :integer          not null
#  line                    :text             not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  delivery_status         :string
#

FactoryBot.define do

  factory :mail_server_log do
    info_request
    mail_server_log_done
    sequence(:order) { |n| n }
    line { 'log line' }
  end

end

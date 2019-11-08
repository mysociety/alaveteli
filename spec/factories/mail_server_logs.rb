# == Schema Information
# Schema version: 20220322100510
#
# Table name: mail_server_logs
#
#  id                      :bigint           not null, primary key
#  mail_server_log_done_id :bigint
#  info_request_id         :bigint
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

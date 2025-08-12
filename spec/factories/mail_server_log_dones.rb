# == Schema Information
# Schema version: 20210114161442
#
# Table name: mail_server_log_dones
#
#  id         :integer          not null, primary key
#  filename   :text             not null
#  last_stat  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do

  factory :mail_server_log_done do
    filename { "/var/log/mail/mail.log-#{ Date.current.to_s(:number )} " }
    last_stat { Time.current }
  end

end

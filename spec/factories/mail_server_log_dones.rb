# -*- encoding : utf-8 -*-
FactoryGirl.define do

  factory :mail_server_log_done do
    filename { "/var/log/mail/mail.log-#{ Date.current.to_s(:number )} "}
    last_stat { Time.current }
  end

end

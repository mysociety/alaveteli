# -*- encoding : utf-8 -*-

namespace :reminder do
  desc 'Send reminder email about public holiday data'
  task :public_holidays => :environment do
    config = MySociety::Config.load_default

    ReminderMailer.public_holidays(config['CONTACT_NAME'],
                                   config['CONTACT_EMAIL'],
                                   "Reminder - update public holidays").deliver
  end
end


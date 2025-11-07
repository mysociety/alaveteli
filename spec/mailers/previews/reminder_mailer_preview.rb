class ReminderMailerPreview < ActionMailer::Preview
  def public_holidays
    name = 'A partner'
    email = 'partner@localhost'
    subject = 'Reminder - update public holidays'
    ReminderMailer.public_holidays(name, email, subject)
  end
end

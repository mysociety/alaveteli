Rails.application.config.after_initialize do
  user_last_created = HealthChecks::Checks::PeriodCheck.new(
    failure_message: _('The last user was created over a day ago'),
    success_message: _('The last user was created in the last day')
  ) do
    User.last.created_at
  end

  incoming_message_last_created = HealthChecks::Checks::PeriodCheck.new(
    failure_message: _('The last incoming message was created over a day ago'),
    success_message: _('The last incoming message was created in the last day')
  ) do
    IncomingMessage.last.created_at
  end

  outgoing_message_last_created = HealthChecks::Checks::PeriodCheck.new(
    failure_message: _('The last outgoing message was created over a day ago'),
    success_message: _('The last outgoing message was created in the last day')
  ) do
    OutgoingMessage.last.created_at
  end

  xapian_queue_check = HealthChecks::Checks::PeriodCheck.new(
    period: 30.minutes,
    failure_message: _('The oldest Xapian index job, has been idle for more ' \
                       'than 30 minutes'),
    success_message: _('The oldest Xapian index job, hasn\'t been idle for ' \
                       'more than 30 minutes')
  ) do
    oldest_job = ActsAsXapian::ActsAsXapianJob.order(:created_at).first
    oldest_job&.created_at || Time.zone.now
  end

  HealthChecks.add user_last_created
  HealthChecks.add incoming_message_last_created
  HealthChecks.add outgoing_message_last_created
  HealthChecks.add xapian_queue_check
end

require 'redis_connection'

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
    period: 1.hour,
    failure_message: _('The Xapian indexing has been stuck for more than 1 ' \
                       'hour'),
    success_message: _('The Xapian indexing is not stuck')
  ) do
    redis = RedisConnection.instance
    last_id = redis.get('health_check_xapian_queue_last_id').to_i

    oldest_job = ActsAsXapian::ActsAsXapianJob.order(:created_at).first
    next Time.zone.now unless oldest_job

    if last_id != oldest_job.id
      redis.set('health_check_xapian_queue_last_id', oldest_job.id)
      redis.set('health_check_xapian_queue_last_changed', Time.zone.now.to_i)
    end

    last_changed = redis.get('health_check_xapian_queue_last_changed').to_i
    Time.zone.at(last_changed)
  end

  HealthChecks.add user_last_created
  HealthChecks.add incoming_message_last_created
  HealthChecks.add outgoing_message_last_created
  HealthChecks.add xapian_queue_check
end

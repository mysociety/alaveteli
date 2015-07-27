# -*- encoding : utf-8 -*-
Rails.application.config.after_initialize do
  user_last_created = HealthChecks::Checks::DaysAgoCheck.new(
                       :failure_message => _('The last user was created over a day ago'),
                       :success_message => _('The last user was created in the last day')) do
                         User.last.created_at 
                       end

  incoming_message_last_created = HealthChecks::Checks::DaysAgoCheck.new(
                                    :failure_message => _('The last incoming message was created over a day ago'),
                                    :success_message => _('The last incoming message was created in the last day')) do
                                      IncomingMessage.last.created_at 
                                  end

  outgoing_message_last_created = HealthChecks::Checks::DaysAgoCheck.new(
                                    :failure_message => _('The last outgoing message was created over a day ago'),
                                    :success_message => _('The last outgoing message was created in the last day')) do
                                      OutgoingMessage.last.created_at 
                                  end

  HealthChecks.add user_last_created
  HealthChecks.add incoming_message_last_created
  HealthChecks.add outgoing_message_last_created
end

Rails.application.config.after_initialize do
    HealthChecks.add HealthChecks::Checks::IncomingMessageCheck.new
    HealthChecks.add HealthChecks::Checks::OutgoingMessageCheck.new
    HealthChecks.add HealthChecks::Checks::UserSignupCheck.new
end

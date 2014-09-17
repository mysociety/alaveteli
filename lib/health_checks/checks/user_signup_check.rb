module HealthChecks
    module Checks
        class UserSignupCheck
            include HealthChecks::HealthCheckable

            def check
                User.last.created_at >= 1.day.ago
            end

        end
    end
end

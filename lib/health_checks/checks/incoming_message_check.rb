module HealthChecks
    module Checks
        class IncomingMessageCheck
            include HealthChecks::HealthCheckable

            def check
                IncomingMessage.last.created_at >= 1.day.ago
            end

        end
    end
end

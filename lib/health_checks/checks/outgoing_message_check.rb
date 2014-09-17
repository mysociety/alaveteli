module HealthChecks
    module Checks
        class OutgoingMessageCheck
            include HealthChecks::HealthCheckable

            def check
                OutgoingMessage.last.created_at >= 1.day.ago
            end

        end
    end
end

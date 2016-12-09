# -*- encoding : utf-8 -*-
class InfoRequest
  module State
    class Calculator

      def initialize(info_request)
        @info_request = info_request
      end

      def phase(cached_value_ok=false)
        if @info_request.awaiting_description?
          :response_received
        else
          state = @info_request.calculate_status(cached_value_ok)
          case state
            when 'not_held',
                 'rejected',
                 'successful',
                 'partially_successful',
                 'user_withdrawn'
              :complete
            when 'waiting_clarification'
              :clarification_needed
            when 'waiting_response'
              :awaiting_response
            when 'gone_postal',
                 'internal_review',
                 'error_message',
                 'requires_admin',
                 'attention_requested',
                 'vexatious',
                 'not_foi'
              :other
          end
        end
      end
    end
  end
end

# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseGatekeeper
    class SpamChecker
      DEFAULT_CONFIGURATION = {
        :spam_action => ::AlaveteliConfiguration.incoming_email_spam_action,
        :spam_header => ::AlaveteliConfiguration.incoming_email_spam_header,
        :spam_threshold => ::AlaveteliConfiguration.incoming_email_spam_threshold
      }

      attr_reader :spam_action, :spam_header, :spam_threshold
      alias_method :rejection_action, :spam_action

      def initialize(opts = {})
        @spam_action = opts[:spam_action] || DEFAULT_CONFIGURATION[:spam_action]
        @spam_header = opts[:spam_header] || DEFAULT_CONFIGURATION[:spam_header]
        @spam_threshold = opts[:spam_threshold] || DEFAULT_CONFIGURATION[:spam_threshold]
      end

      def allow?(email)
        configured? ? !spam?(email) : true
      end

      def reason
        _('Incoming message has a spam score above the configured threshold ' \
          '({{spam_threshold}}).', :spam_threshold => spam_threshold)
      end

      def spam?(email)
        spam_score(email) > spam_threshold
      end

      def spam_score(email)
        email.header[spam_header].try(:value).to_f
      end

      def configured?
        (spam_action && spam_header && spam_threshold) ? true : false
      end
    end
  end
end

class InfoRequest
  module ResponseGatekeeper
    class SpamChecker
      DEFAULT_CONFIGURATION = {
        spam_action: ::AlaveteliConfiguration.incoming_email_spam_action,
        spam_header: ::AlaveteliConfiguration.incoming_email_spam_header,
        spam_threshold: ::AlaveteliConfiguration.incoming_email_spam_threshold
      }

      attr_reader :spam_action, :spam_header, :spam_threshold
      alias rejection_action spam_action

      def initialize(opts = {})
        @spam_action = opts[:spam_action] || DEFAULT_CONFIGURATION[:spam_action]
        @spam_header = opts[:spam_header] || DEFAULT_CONFIGURATION[:spam_header]
        @spam_threshold = opts[:spam_threshold] || DEFAULT_CONFIGURATION[:spam_threshold]
      end

      def allow?(mail)
        configured? ? !spam?(mail) : true
      end

      def reason
        _('Incoming message has a spam score above the configured threshold ' \
          '({{spam_threshold}}).', spam_threshold: spam_threshold)
      end

      def spam?(mail)
        spam_score(mail) > spam_threshold
      end

      def spam_score(mail)
        mail.header[spam_header].try(:value).to_f
      end

      def configured?
        (spam_action && spam_header && spam_threshold) ? true : false
      end
    end
  end
end

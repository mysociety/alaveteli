require File.join(File.dirname(__FILE__), 'regexp_masker')

module AlaveteliTextMasker
  module TextMasks
    # Public: A middleware to replace email addresses with a redaction String
    class EmailAddressMasker < RegexpMasker
      EMAIL_REGEXP = /(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b)/
      DEFAULT_EMAIL_REPLACEMENT = _('[email address]')

      def self.defaults
        { :regexp => EMAIL_REGEXP,
          :replacement => DEFAULT_EMAIL_REPLACEMENT }
      end

      # Public: Initialize an EmailAddressMasker
      #
      # app  - a middleware that responds to #call
      # opts - Hash to supply replacement rules
      #        :replacement  - String to replace matches with
      #                        (default: '[email address]')
      def initialize(app, opts = {})
        # TODO: Refactor options setting
        # opts = opts.merge(self.class.defaults)

        new_opts = {}
        new_opts[:regexp] = EMAIL_REGEXP
        new_opts[:replacement] = opts.fetch(:replacement, DEFAULT_EMAIL_REPLACEMENT)

        super(app, new_opts)
      end
    end
  end
end

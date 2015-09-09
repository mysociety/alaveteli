require File.join(File.dirname(__FILE__), 'regexp_masker')

module AlaveteliTextMasker
  module TextMasks
    # Public: A middleware to replace email addresses with a redaction String
    class EmailAddressMasker < RegexpMasker
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
        new_opts[:regexp] = /(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}\b)/
        new_opts[:replacement] = opts.fetch(:replacement) { _('[email address]') }

        super(app, new_opts)
      end
    end
  end
end

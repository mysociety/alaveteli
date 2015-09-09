module AlaveteliTextMasker
  module TextMasks
    # Public: A simple middleware to replace text matched by a Regexp with a
    # replacement String
    class RegexpMasker
      # HACK: Used lambda because it looks like constants are assigned before
      # FastGettext is configured, causing specs to fail with:
      #   Current textdomain (nil) was not added, use
      #   FastGettext.add_text_domain !
      #   (FastGettext::Storage::NoTextDomainConfigured)
      DEFAULT_REPLACEMENT_STRING = -> { _('[REDACTED]') }

      attr_reader :regexp, :replacement

      # Public: Initialize a RegexpMasker
      #
      # app  - a middleware that responds to #call
      # opts - Hash to supply replacement rules
      #        :regexp       - Regexp to match against
      #        :replacement  - String to replace matches with
      #                        (default: '[REDACTED]')
      def initialize(app, opts = {})
        @app = check_app(app)
        @regexp = opts.fetch(:regexp)
        @replacement = opts.fetch(:replacement, DEFAULT_REPLACEMENT_STRING)
      end

      # Public: Perform the replacement and call the next middleware
      #
      # env - String to process
      #
      # Returns a String
      def call(env)
        app.call(env.gsub(regexp, replacement))
      end

      private

      attr_reader :app

      def check_app(app)
        raise ArgumentError unless app.respond_to?(:call)
        app
      end
    end
  end
end

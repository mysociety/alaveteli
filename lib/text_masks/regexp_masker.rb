module AlaveteliTextMasker
  module TextMasks
    # Public: A simple middleware to replace text matched by a Regexp with a
    # replacement String
    class RegexpMasker
      DEFAULT_REPLACEMENT_STRING = '[REDACTED]'

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

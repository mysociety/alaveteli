module HealthChecks
  module Checks
    class LimitCheck
      include HealthChecks::HealthCheckable

      attr_reader :limit, :subject

      def initialize(args = {}, &block)
        @limit = args.fetch(:limit) { 500 }
        @subject = block
        super(args)
      end

      def failure_message
        "#{ super }: #{ subject.call }"
      end

      def success_message
        "#{ super }: #{ subject.call }"
      end

      def ok?
        subject.call < limit
      end

    end
  end
end

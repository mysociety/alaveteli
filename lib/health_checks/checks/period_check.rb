module HealthChecks
  module Checks
    class PeriodCheck
      include HealthChecks::HealthCheckable

      attr_reader :period, :subject

      def initialize(args = {}, &block)
        @period = args.fetch(:period) { 1.day }
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
        subject.call >= period.ago
      end
    end
  end
end

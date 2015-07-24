# -*- encoding : utf-8 -*-
module HealthChecks
  module Checks
    class DaysAgoCheck
      include HealthChecks::HealthCheckable

      attr_reader :days, :subject

      def initialize(args = {}, &block)
        @days = args.fetch(:days) { 1 }
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
        subject.call >= days.days.ago
      end

    end
  end
end

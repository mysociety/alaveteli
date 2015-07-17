# -*- encoding : utf-8 -*-
module HealthChecks
  module HealthCheckable

    attr_accessor :failure_message, :success_message

    def initialize(args = {})
      self.failure_message = args.fetch(:failure_message) { _('Failed') }
      self.success_message = args.fetch(:success_message) { _('Success') }
    end

    def name
      self.class.to_s
    end

    def ok?
      raise NotImplementedError
    end

    def message
      ok? ? success_message : failure_message
    end

  end
end

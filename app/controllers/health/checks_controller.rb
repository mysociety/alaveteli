module Health
  ##
  # This controller is responsible for running health checks and returning
  # either a 200 or 500 response for internal monitoring alerting
  #
  # See checks configured in config/initializers/health_checks.rb
  #
  class ChecksController < ApplicationController
    def index
      @health_checks = HealthChecks.all

      if HealthChecks.ok?
        render action: :index, layout: false
      else
        render action: :index, layout: false , status: 500
      end
    end
  end
end

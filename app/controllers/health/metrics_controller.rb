module Health
  ##
  # This controller is responsible for providing an overview of system metrics
  # for internal monitoring checks
  #
  class MetricsController < ApplicationController
    skip_before_action :html_response

    layout false

    def index
      @sidekiq_stats = Sidekiq::Stats.new
    end
  end
end

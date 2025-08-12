class HealthChecksController < ApplicationController

  def index
    @health_checks = HealthChecks.all

    if HealthChecks.ok?
      render :action => :index, :layout => false
    else
      render :action => :index, :layout => false , :status => 500
    end
  end

end

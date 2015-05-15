# -*- encoding : utf-8 -*-
class HealthChecksController < ApplicationController

  def index
    @health_checks = HealthChecks.all

    respond_to do |format|
      if HealthChecks.ok?
        format.html  { render :action => :index, :layout => false }
      else
        format.html  { render :action => :index, :layout => false , :status => 500 }
      end
    end

  end

end

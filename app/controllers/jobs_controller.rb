class JobsController < ApplicationController
  def index
  end

  def start
    LongRunningJob.perform_later(current_user&.id)
    redirect_to jobs_path
  end
end

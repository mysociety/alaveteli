class StatisticsController < ApplicationController
  def index
    unless AlaveteliConfiguration::public_body_statistics_page
      raise ActiveRecord::RecordNotFound.new("Page not enabled")
    end

    @public_bodies = Statistics.public_bodies
    @users = Statistics.users

    respond_to do |format|
      format.html
      format.json do
        render json: {
          public_bodies: @public_bodies,
          users: Statistics.user_json_for_api(@users)
        }
      end
    end
  end
end

class StatisticsController < ApplicationController
  def index
    unless AlaveteliConfiguration::public_body_statistics_page
      raise ActiveRecord::RecordNotFound.new("Page not enabled")
    end

    @public_bodies = Statistics.public_bodies
    @users = Statistics.users
    @request_hides_by_week = Statistics.by_week_to_today_with_noughts(
      InfoRequestEvent.count_of_hides_by_week,
      InfoRequest.is_public.order(:created_at).first.created_at
    )

    respond_to do |format|
      format.html
      format.json do
        render json: {
          public_bodies: @public_bodies,
          users: Statistics.user_json_for_api(@users),
          requests: {
            hides_by_week: @request_hides_by_week
          }
        }
      end
    end
  end
end

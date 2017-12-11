class AnnouncementsController < ApplicationController
  before_action :authenticate

  def destroy
    AnnouncementDismissal.find_or_create_by(
      announcement: announcement,
      user: current_user
    )

    render nothing: true, status: 200
  end

  private

  def authenticate
    render nothing: true, status: 403 unless current_user && announcement
  end

  def announcement
    @announcement ||= Announcement.find_by(id: params.require(:id))
  end
end

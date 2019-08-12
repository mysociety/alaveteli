class AnnouncementsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:destroy]

  def destroy
    if announcement
      store_dismissal_in_session unless dismissal.save
      head :ok
    else
      head :forbidden
    end
  end

  private

  def dismissal
    @dismissal ||= AnnouncementDismissal.find_or_initialize_by(
      announcement: announcement,
      user: current_user
    )
  end

  def announcement
    @announcement ||= Announcement.find_by(id: params.require(:id))
  end

  def store_dismissal_in_session
    session[:announcement_dismissals] ||= Array.new
    session[:announcement_dismissals] << announcement.id
  end
end

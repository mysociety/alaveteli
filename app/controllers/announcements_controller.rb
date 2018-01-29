class AnnouncementsController < ApplicationController
  def destroy
    if announcement
      store_dismissal_in_session unless dismissal.save
      render nothing: true, status: 200
    else
      render nothing: true, status: 403
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

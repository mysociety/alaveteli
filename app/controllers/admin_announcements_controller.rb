class AdminAnnouncementsController < AdminController
  before_action :set_announcement, only: %i[edit update destroy]

  def index
    @title = 'Announcements'
    @announcements = Announcement.
      paginate(page: params[:page], per_page: 25)
  end

  def new
    @title = 'New announcement'
    @announcement = Announcement.new
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.save
      notice = 'Announcement successfully created.'
      redirect_to admin_announcements_path, notice: notice
    else
      @title = 'New announcement'
      render :new
    end
  end

  def edit
    @title = 'Edit announcement'
  end

  def update
    if @announcement.update_attributes(announcement_params)
      notice = 'Announcement successfully updated.'
      redirect_to admin_announcements_path, notice: notice
    else
      @title = 'Edit announcement'
      render :edit
    end
  end

  def destroy
    @announcement.destroy
    notice = 'Announcement successfully destroyed'
    redirect_to admin_announcements_path, notice: notice
  end

  private

  def announcement_params
    if params[:announcement]
      params.require(:announcement).permit(:title, :content)
    else
      {}
    end
  end

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end
end

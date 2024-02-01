class Admin::CitationsController < AdminController
  def index
    @citations =
      Citation.
      order(created_at: :desc).
      paginate(page: params[:page], per_page: 50)
  end
end

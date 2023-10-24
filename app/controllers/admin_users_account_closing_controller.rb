##
# Controller for closing user accounts
#
class AdminUsersAccountClosingController < AdminController
  before_action :set_closed_user

  def create
    if close
      flash[:notice] = 'The user account was closed.'
    else
      flash[:error] =
        'Something went wrong. The user account could not be closed.'
    end

    redirect_to admin_user_path(@closed_user)
  end

  private

  def set_closed_user
    @closed_user = User.find(params[:user_id])
  end

  def close
    @closed_user.close
  end
end

##
# Controller for erasing accounts
#
class Admin::Users::ErasuresController < AdminController
  before_action :set_erased_user

  def create
    if @erased_user.erase(editor: admin_current_user, reason: reason)
      flash[:notice] = 'The user was erased.'
    else
      flash[:error] = 'Something went wrong. The user could not be erased.'
    end

    redirect_to admin_user_path(@erased_user)
  end

  private

  def set_erased_user
    @erased_user = User.find(params[:user_id])
  end

  def reason
    params[:reason]
  end
end

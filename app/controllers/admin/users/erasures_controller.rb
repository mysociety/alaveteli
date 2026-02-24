##
# Controller for erasing accounts
#
class Admin::Users::ErasuresController < AdminController
  before_action :set_erased_user

  def create
    @erased_user.erase!(editor: admin_current_user, reason: reason)
    redirect_to admin_user_path(@erased_user), notice: 'Erasure queued'
  end

  private

  def set_erased_user
    @erased_user = User.find(params[:user_id])
  end

  def reason
    params[:reason]
  end
end

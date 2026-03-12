##
# Controller for erasing accounts
#
class Admin::Users::ErasuresController < AdminController
  before_action :set_erased_user, :ensure_erasable

  def create
    @erased_user.erase_later(editor: admin_current_user, reason: reason)
    redirect_to admin_user_path(@erased_user), notice: erasure_queued
  end

  private

  def set_erased_user
    @erased_user = User.find(params[:user_id])
  end

  def ensure_erasable
    return if @erased_user.closed?

    flash[:error] = 'User accounts must be closed before erasing.'
    redirect_to admin_user_path(@erased_user)
  end

  def reason
    params[:reason]
  end

  def erasure_queued
    'Erasure has been queued.'
  end
end

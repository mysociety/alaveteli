# Controller for managing PostRedirects
class Admin::PostRedirectsController < AdminController
  before_action :set_post_redirect, only: %i[destroy]

  # DELETE /admin/post_redirects
  def destroy
    @post_redirect.destroy
    notice = 'Post redirect successfully destroyed.'
    redirect_to admin_user_path(@post_redirect.user), notice: notice
  end

  private

  def set_post_redirect
    @post_redirect ||= PostRedirect.find(params[:id])
  end
end

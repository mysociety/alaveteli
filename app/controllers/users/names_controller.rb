##
# Controller to allow current user to change their name
#
class Users::NamesController < ApplicationController
  before_action :check_user_logged_in, :check_user_suspension, :load_user

  def update
    if @edit_user.update(user_params)
      flash[:notice] = _('Name successfully updated.')
      redirect_to user_url(@edit_user)
    else
      render action: 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end

  def check_user_logged_in
    return if authenticated?

    flash[:error] = _('You need to be logged in to change your name')
    redirect_to frontpage_url
  end

  def check_user_suspension
    return unless current_user.suspended?

    flash[:error] = _('Suspended users cannot edit their profile')
    redirect_to edit_profile_about_me_path
  end

  def load_user
    # Don't make changes to the current_user, this could brake the layout as we
    # use name/url_name in the login bar URLs
    @edit_user = User.find_by(url_name: current_user.url_name)
  end
end

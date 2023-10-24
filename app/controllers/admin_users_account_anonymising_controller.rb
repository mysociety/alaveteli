##
# Controller for anonymising user accounts
#
class AdminUsersAccountAnonymisingController < AdminController
  before_action :set_anonymised_user

  def create
    if anonymise
      flash[:notice] = 'The user was anonymised.'
    else
      flash[:error] = 'Something went wrong. The user could not be anonymised.'
    end

    redirect_to admin_user_path(@anonymised_user)
  end

  private

  def set_anonymised_user
    @anonymised_user = User.find(params[:user_id])
  end

  def anonymise
    @anonymised_user.anonymise!
  end
end

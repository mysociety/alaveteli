##
# Controller responsible for remove user slugs
#
class AdminUserSlugController < AdminController
  before_action :set_admin_user, :set_slug

  def destroy
    @slug.destroy unless @slug.slug == @admin_user.url_name
    redirect_to [:admin, @admin_user]
  end

  private

  def set_admin_user
    # Don't use @user as that is any logged in user
    @admin_user = User.find(params[:user_id])
  end

  def set_slug
    @slug = @admin_user.slugs.find(params[:id])
  end
end

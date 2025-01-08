# Manage a Project's contributors
class Projects::ContributorsController < Projects::BaseController
  def destroy
    return unless authenticate!

    authorize! :leave, @project
    @project.contributors.destroy(current_user)

    redirect_to root_path, notice: _('You have left the project.')
  end

  private

  def authenticate!
    post_redirect = PostRedirect.new(
      uri: project_path(@project),
      post_params: params,
      reason_params: {
        web: _('To leave this project'),
        email: _('Then you can leave this project'),
        email_subject: _('Confirm your account on {{site_name}}',
                         site_name: site_name)
      }
    )

    authenticated? || ask_to_login(post_redirect: post_redirect)
  end
end

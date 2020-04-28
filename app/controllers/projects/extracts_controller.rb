# Extract data from a Project
class Projects::ExtractsController < Projects::BaseController
  before_action :authenticate

  def show
    @project = Project.find(params[:project_id])
    authorize! :read, @project
  end

  private

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end
end

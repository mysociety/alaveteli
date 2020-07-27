# View and manage Projects
class Projects::ProjectsController < Projects::BaseController
  before_action :authenticate

  def show
    authorize! :read, @project
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end
end

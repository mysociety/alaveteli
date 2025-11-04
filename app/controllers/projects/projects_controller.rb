# View and manage Projects
class Projects::ProjectsController < Projects::BaseController
  before_action :authenticate

  def show
    authorize! :read, @project
    session.delete(:new_project)
    @leaderboard = Project::Leaderboard.new(@project)
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

  def authenticate
    authenticated? || ask_to_login(web: _('To view this project'))
  end
end

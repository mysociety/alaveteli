##
# Projects controller, for pro user self serve projects.
#
class AlaveteliPro::ProjectsController < AlaveteliPro::BaseController
  def index
    @projects = current_user.projects.owner.paginate(
      page: params[:page], per_page: 10
    )
  end

  def new
    @project = current_user.projects.owner.new
  end

  def create
    @project = current_user.projects.new

    if @project.update(project_params.merge(owner: current_user))
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  private

  def project_params
    params.require(:project).permit(:title, :briefing)
  end
end

##
# Display and administer projects
#
class Admin::ProjectsController < AdminController
  include Admin::Sortable

  before_action :set_project, except: :index
  before_action :authorise

  sortable default: :created_at_desc, only: [:index]

  def index
    @query = params[:query]
    if @query
      projects = Project.where("lower(title) like lower('%'||?||'%')", @query)
    else
      projects = Project
    end

    @projects = projects.includes(:owner, :contributors, :resources).
                         order(sort_query).
                         paginate(page: params[:page], per_page: 50)
  end

  def show
  end

  def edit
  end

  def update
    if @project.update(project_params)
      flash[:notice] = 'Project was successfully updated.'
      redirect_to admin_project_path(@project)
    else
      render :edit
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = 'Project was successfully deleted.'
    redirect_to admin_projects_path
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def authorise
    authorize! :admin, @project || Project
  end

  def project_params
    params.require(:project).permit(
      :title,
      :briefing,
      :dataset_public,
      :dataset_description,
      :invite_token_action
    )
  end
end

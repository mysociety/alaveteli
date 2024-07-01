##
# Projects controller, for pro user self serve projects.
#
class AlaveteliPro::ProjectsController < AlaveteliPro::BaseController
  skip_before_action :html_response, only: [:update_resources]

  before_action :find_project, only: [
    :edit, :update,
    :edit_resources, :update_resources
  ]

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
      redirect_to_next_step notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to_next_step notice: 'Project was successfully updated.'
    else
      render current_step, status: :unprocessable_entity
    end
  end

  def edit_resources
    @batches = @project.batches.order(:title, :id).distinct
    @requests = @project.requests.order(:title, :id).distinct
    @results = current_user.info_requests.
      order(:title, :id).
      paginate(page: current_page, per_page: 10)
  end

  def update_resources
    @batches = current_user.info_request_batches.
      where(id: project_params[:batch_ids]).
      order(:title, :id).
      distinct
    @requests = current_user.info_requests.
      where(id: project_params[:request_ids]).
      order(:title, :id).
      distinct
    @results = current_user.info_requests.
      where("title ILIKE ?", "%#{params[:query]}%").
      order(:title, :id).
      paginate(page: current_page, per_page: 10)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def find_project
    @project = current_user.projects.owner.find(params[:id])
    authorize! :edit, @project
  end

  def current_page
    params.fetch(:page, 1)
  end
  helper_method :current_page

  def current_step
    params.fetch(:step, action_name)
  end
  helper_method :current_step

  def pending_steps
    steps = []
    steps << 'edit' unless @project.persisted?
    steps << 'edit_resources' unless @project.info_requests.any?
    steps
  end

  def next_step
    pending_steps.first
  end

  def project_params
    case current_step
    when 'edit_resources', 'update_resources'
      params.fetch(:project, {}).permit(request_ids: [], batch_ids: []).
        with_defaults(request_ids: [], batch_ids: [])
    else
      params.require(:project).permit(:title, :briefing)
    end
  end

  def redirect_to_next_step(**args)
    if next_step
      redirect_to action: next_step, id: @project.to_param
    else
      redirect_to @project, **args
    end
  end
end

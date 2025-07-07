##
# Projects controller, for pro user self serve projects.
#
class AlaveteliPro::ProjectsController < AlaveteliPro::BaseController
  skip_before_action :html_response, only: [
    :update_resources, :update_key_set, :update_contributors
  ]

  before_action :find_project, only: [
    :edit, :update,
    :edit_resources, :update_resources,
    :edit_key_set, :update_key_set,
    :edit_contributors, :update_contributors
  ]

  PER_PAGE = 10

  def index
    @projects = current_user.projects.owner.paginate(
      page: params[:page], per_page: PER_PAGE
    )
  end

  def new
    @project = current_user.projects.owner.new
  end

  def create
    @project = current_user.projects.new

    if @project.update(project_params.merge(owner: current_user))
      session[:new_project] = true
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
      paginate(page: current_page, per_page: PER_PAGE)
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
      paginate(page: current_page, per_page: PER_PAGE)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def edit_key_set
    @key_set = @project.key_set || @project.build_key_set
    @key_set.keys.build(order: 1) if @key_set.keys.empty?
    @keys = @key_set.keys
  end

  def update_key_set
    @project.assign_attributes(project_params)

    @key_set = @project.key_set || @project.build_key_set
    @key_set.keys.build if @key_set.keys.empty? || params[:new]
    @keys = @key_set.keys
  end

  def edit_contributors
    @contributors = @project.contributors.
      order(:name, :id).
      distinct
  end

  def update_contributors
    @contributors = @project.contributors.
      where(id: project_params[:contributor_ids]).
      order(:name, :id).
      distinct
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

  def steps
    %w[edit_resources edit_key_set edit_contributors]
  end

  def next_step
    current_step_index = steps.index(current_step)
    return steps.first unless current_step_index

    steps[current_step_index + 1]
  end

  def next_step_path
    return project_path unless next_step

    url_for(action: next_step, id: @project.to_param)
  end
  helper_method :next_step_path

  def project_params
    case current_step
    when 'edit_resources', 'update_resources'
      params.fetch(:project, {}).permit(request_ids: [], batch_ids: []).
        with_defaults(request_ids: [], batch_ids: [])
    when 'edit_key_set', 'update_key_set'
      params.fetch(:project, {}).permit(
        key_set_attributes: [
          :id, keys_attributes: [
            :id, :title, :format, :order, :_destroy, options: [
              :select_allow_blank, :select_allow_multiple, { select_options: [] }
            ]
          ]
        ]
      )
    when 'edit_contributors', 'update_contributors'
      params.fetch(:project, {}).permit(contributor_ids: []).
        with_defaults(contributor_ids: [])
    when 'invite'
      { regenerate_invite_token: true }
    else
      params.require(:project).permit(:title, :briefing)
    end
  end

  def redirect_to_next_step(**args)
    if current_step == 'invite'
      redirect_to action: 'edit_contributors', id: @project.to_param
    elsif session[:new_project] && next_step
      redirect_to next_step_path
    else
      session.delete(:new_project)
      redirect_to @project, **args
    end
  end
end

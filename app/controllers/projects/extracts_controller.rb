require_dependency 'project/queue'

# Extract data from a Project
class Projects::ExtractsController < Projects::BaseController
  before_action :authenticate

  before_action :load_info_request_from_queue, only: :show
  before_action :load_info_request_from_url_title, except: :show
  attr_reader :info_request

  before_action :redirect_to_project_if_queue_is_empty, only: :show

  before_action :find_submission, except: [:skip, :create]

  def show
  end

  def skip
    queue = Project::Queue.extractable(@project, session)
    queue.skip(info_request)

    redirect_to project_extract_path, notice: _('Skipped!')
  end

  def create
    @submission = @project.submissions.new(**submission_params)

    if @submission.save
      flash[:notice] = _('Extraction saved successfully!')
      redirect_to params.fetch(:r, project_extract_path)
    else
      flash.now[:error] = _("Extraction couldn't be saved.")
      render :show
    end
  end

  def edit
    @info_request = @submission.info_request
    @value_set = @submission.resource

    render :show
  end

  def update
    @value_set = Dataset::ValueSet.new(extract_params)
    @submission = @submission.create_new_version(
      user: current_user, **submission_params
    )

    if @submission.persisted?
      flash[:notice] = _('Extraction updated successfully!')
      redirect_to project_dataset_path
    else
      flash.now[:error] = _("Extraction couldn't be updated.")
      render :show
    end
  end

  private

  def authenticate
    return authorize!(:read, @project) if authenticated?

    ask_to_login(
      web: _('To extract data for this project'),
      email: _('Then you can extract data for this project')
    )
  end

  def find_submission
    @submission = (
      if params[:resource_id].present?
        resource = @project.key_set.value_sets.find(params[:resource_id])
        scope = @project.submissions.extraction.where(resource: resource)
        scope.last || scope.new
      else
        @project.submissions.new(resource: Dataset::ValueSet.new)
      end
    )
  end

  def load_info_request_from_queue
    @info_request = (
      @queue = Project::Queue.extractable(@project, session)
      @queue.next
    )
  end

  def load_info_request_from_url_title
    @info_request = @project.info_requests.find_by!(
      url_title: params.require(:url_title)
    )
  end

  def redirect_to_project_if_queue_is_empty
    return if info_request

    if @project.info_requests.extractable.any?
      msg = _('Nice work! How about having another try at the requests you ' \
              'skipped?')
      @queue.reset
    else
      msg = _('There are no requests to extract right now. Great job!')
    end

    redirect_to @project, notice: msg
  end

  def extract_params
    params.require(:extract).permit(
      :dataset_key_set_id, values_attributes: [:dataset_key_id, :value, value: []]
    )
  end

  def submission_params
    value_set = Dataset::ValueSet.new(extract_params)
    {
      user: current_user,
      info_request: info_request,
      resource: value_set
    }
  end
end

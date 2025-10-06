require_dependency 'project/queue'

# Extract data from a Project
class Projects::ExtractsController < Projects::BaseController
  before_action :authenticate

  before_action :load_info_request_from_queue, only: :show
  before_action :load_info_request_from_url_title, except: :show
  attr_reader :info_request

  def show
    authorize! :read, @project

    unless @info_request
      if @project.info_requests.extractable.any?
        msg = _('Nice work! How about having another try at the requests you ' \
                'skipped?')
        @queue.reset
      else
        msg = _('There are no requests to extract right now. Great job!')
      end

      redirect_to @project, notice: msg
      return
    end

    @value_set = Dataset::ValueSet.new
  end

  def skip
    authorize! :read, @project

    queue = Project::Queue.extractable(@project, session)
    queue.skip(@info_request)

    redirect_to project_extract_path(@project), notice: _('Skipped!')
  end

  def create
    authorize! :read, @project

    @value_set = Dataset::ValueSet.new(extract_params)
    submission = @project.submissions.new(**submission_params)

    if submission.save
      redirect_to project_extract_path
    else
      flash.now[:error] = _("Extraction couldn't be saved.")
      render :show
    end
  end

  private

  def authenticate
    authenticated? || ask_to_login(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end

  def load_info_request_from_queue
    @info_request = (
      @queue = Project::Queue.extractable(@project, session)
      @queue.next
    )
  end

  def load_info_request_from_url_title
    @info_request = @project.info_requests.extractable.find_by!(
      url_title: params.require(:url_title)
    )
  end

  def extract_params
    params.require(:extract).permit(
      :dataset_key_set_id, values_attributes: [:dataset_key_id, :value, value: []]
    )
  end

  def submission_params
    {
      user: current_user,
      info_request: @info_request,
      resource: @value_set
    }
  end
end

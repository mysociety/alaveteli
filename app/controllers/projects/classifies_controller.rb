require_dependency 'project/queue'

# Classify a request in a Project
class Projects::ClassifiesController < Projects::BaseController
  before_action :authenticate

  before_action :load_info_request_from_queue, only: :show
  before_action :load_info_request_from_url_title, except: :show
  attr_reader :info_request

  before_action :redirect_to_project_if_queue_is_empty, only: :show

  before_action :assign_state_transition_variables, except: :skip

  before_action :find_submission, except: [:skip, :create]

  include Classifiable

  def show
  end

  def skip
    queue = Project::Queue.classifiable(@project, session)
    queue.skip(info_request)

    redirect_to project_classify_path(@project), notice: _('Skipped!')
  end

  def create
    @submission = @project.submissions.new(**submission_params)

    if @submission.save
      flash[:notice] = _('Classification saved successfully!')
      redirect_to project_classify_path
    else
      flash.now[:error] = _("Classification couldn't be saved.")
      render :show
    end
  end

  def edit
    render :show
  end

  def update
    @submission = @submission.create_new_version(
      user: current_user, **submission_params
    )

    if @submission.persisted?
      flash[:notice] = _('Classification updated successfully!')
      redirect_to project_dataset_path(@project)
    else
      flash.now[:error] = _("Classification couldn't be updated.")
      render :show
    end
  end

  private

  def authenticate
    return authorize!(:read, @project) if authenticated?

    ask_to_login(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end

  def find_submission
    @submission = (
      if params[:resource_id].present?
        resource = info_request.info_request_events.find(params[:resource_id])
        scope = @project.submissions.classification.where(resource: resource)
        scope.last || scope.new
      else
        @project.submissions.new(resource: InfoRequestEvent.new)
      end
    )
  end

  def load_info_request_from_queue
    @info_request = (
      @queue = Project::Queue.classifiable(@project, session)
      @queue.next
    )
  end

  def load_info_request_from_url_title
    @info_request = @project.info_requests.find_by!(
      url_title: params.require(:url_title)
    )
  end

  def assign_state_transition_variables
    return unless info_request

    @state_transitions = info_request.state.transitions(
      is_pro_user: false,
      is_owning_user: false,
      in_internal_review: info_request.described_state == 'internal_review',
      user_asked_to_update_status: false
    )
  end

  def redirect_to_project_if_queue_is_empty
    return if info_request


    if @project.info_requests.classifiable.any?
      msg = _('Nice work! How about having another try at the requests you ' \
              'skipped?')
      @queue.reset
    else
      msg = _('There are no requests to classify right now. Great job!')
    end

    redirect_to @project, notice: msg
  end

  def submission_params
    {
      user: current_user,
      info_request: info_request,
      resource: set_described_state
    }
  end
end

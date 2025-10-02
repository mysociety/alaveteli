require_dependency 'project/queue'

# Classify a request in a Project
class Projects::ClassifiesController < Projects::BaseController
  before_action :authenticate

  before_action :load_info_request_from_queue, only: :show
  before_action :load_info_request_from_url_title, except: :show
  attr_reader :info_request

  def show
    unless info_request
      if @project.info_requests.classifiable.any?
        msg = _('Nice work! How about having another try at the requests you ' \
                'skipped?')
        @queue.reset
      else
        msg = _('There are no requests to classify right now. Great job!')
      end

      redirect_to @project, notice: msg
      return
    end

    @state_transitions = info_request.state.transitions(
      is_pro_user: false,
      is_owning_user: false,
      in_internal_review: info_request.described_state == 'internal_review',
      user_asked_to_update_status: false
    )
  end

  def skip
    queue = Project::Queue.classifiable(@project, session)
    queue.skip(info_request)

    redirect_to project_classify_path(@project), notice: _('Skipped!')
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

  def load_info_request_from_queue
    @info_request = (
      @queue = Project::Queue.classifiable(@project, session)
      @queue.next
    )
  end

  def load_info_request_from_url_title
    @info_request = @project.info_requests.classifiable.find_by!(
      url_title: params.require(:url_title)
    )
  end
end

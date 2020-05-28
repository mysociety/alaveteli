# Classify a request in a Project
class Projects::ClassifiesController < Projects::BaseController
  before_action :authenticate

  def show
    authorize! :read, @project

    @queue = Project::Queue::Classifiable.new(@project, current_user, session)
    @info_request = @queue.next

    unless @info_request
      msg = _('There are no requests to classify right now. Great job!')
      redirect_to @project, notice: msg
      return
    end

    @state_transitions = @info_request.state.transitions(
      is_pro_user: false,
      is_owning_user: false,
      in_internal_review: @info_request.described_state == 'internal_review',
      user_asked_to_update_status: false
    )
  end

  private

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end
end

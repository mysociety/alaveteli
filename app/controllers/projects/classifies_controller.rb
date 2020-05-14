# Classify a request in a Project
class Projects::ClassifiesController < Projects::BaseController
  before_action :authenticate

  def show
    authorize! :read, @project

    @info_request =
      @project.info_requests.where(awaiting_description: true).sample
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

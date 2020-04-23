# View and manage Projects
class Projects::ProjectsController < ApplicationController
  before_action :authenticate

  def show
    @project = Project.find(params[:id])
    authorize! :read, @project
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

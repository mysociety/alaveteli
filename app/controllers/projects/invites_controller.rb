# Invite contributors to a Project
class Projects::InvitesController < Projects::BaseController
  before_action :authenticate

  def create
    if @project.member?(current_user)
      flash[:notice] = _('You are already a member of this project')
    else
      @project.contributors << current_user
      flash[:notice] = _('Welcome to the project!')
    end

    redirect_to @project
  end

  private

  def find_project
    @project = Project.find_by!(invite_token: params[:token])
  end

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end
end

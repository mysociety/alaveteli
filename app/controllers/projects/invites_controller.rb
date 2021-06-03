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
    sign_in_as_demo_user unless current_user
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end

  def sign_in_as_demo_user
    session[:user_id] = create_demo_user.id
  end

  def create_demo_user
    user = nil

    loop do
      uuid = SecureRandom.hex(3)
      user = User.new(
        name: "Demo User #{uuid}",
        email: "foi-demo-#{uuid}@localhost",
        email_confirmed: true,
        password: uuid * 3
      )
      break unless User.find_by(email: user.email)
    end

    user if user.save!
  end
end

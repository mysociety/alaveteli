# View and manage Projects
class Projects::ProjectsController < ApplicationController
  before_action :check_feature_enabled
  before_action :authenticate
  before_action :set_in_pro_area

  def show
    @project = Project.find(params[:id])
    authorize! :read, @project
  end

  private

  def check_feature_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:projects)
  end

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end

  def set_in_pro_area
    @in_pro_area = true
  end
end

# View and manage Projects
class Projects::BaseController < ApplicationController
  before_action :check_feature_enabled
  before_action :set_in_pro_area
  before_action :find_project

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def check_feature_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:projects)
  end

  def set_in_pro_area
    @in_pro_area = true
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, project: @project)
  end
end

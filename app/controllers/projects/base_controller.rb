# View and manage Projects
class Projects::BaseController < ApplicationController
  before_action :check_feature_enabled
  before_action :set_in_pro_area

  private

  def check_feature_enabled
    raise ActiveRecord::RecordNotFound unless feature_enabled?(:projects)
  end

  def set_in_pro_area
    @in_pro_area = true
  end
end

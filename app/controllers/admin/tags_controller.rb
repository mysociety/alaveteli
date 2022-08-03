class Admin::TagsController < AdminController
  include Admin::TagHelper

  before_action :check_klass

  # GET /admin/tags
  def index
    scope = HasTagString::HasTagStringTag.distinct.
      select(:name, :value, :model_type).
      where(model_type: current_klass.name).
      order(:name, :value)

    @tags = scope.paginate(page: params[:page], per_page: 50)
  end

  # GET /admin/tags/:tag
  def show
    @tag = params[:tag]
    @name, @value = HasTagString::HasTagStringTag.split_tag_into_name_value(
      @tag
    )

    @taggings = current_klass.with_tag(@tag).distinct.
      paginate(page: params[:page], per_page: 50)
  end

  private

  helper_method :current_klass
  def current_klass
    params.fetch(:model_type, 'PublicBody').safe_constantize
  end

  def check_klass
    raise RouteNotFound unless Taggable.models.include?(current_klass)
  end
end

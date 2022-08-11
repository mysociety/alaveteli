class Admin::TagsController < AdminController
  include Admin::TagHelper

  before_action :check_klass

  # GET /admin/tags
  def index
    scope = HasTagString::HasTagStringTag.distinct.
      select(:name, :value, :model_type).
      where(model_type: current_klass.name).
      order(:name, :value)

    scope = apply_filters(scope)

    @tags = scope.paginate(page: params[:page], per_page: 50)
  end

  # GET /admin/tags/:tag
  def show
    @tag = params[:tag]
    @name, @value = HasTagString::HasTagStringTag.split_tag_into_name_value(
      @tag
    )

    @taggings = current_klass.with_tag(@tag).distinct.
      joins(:tags).merge(
        apply_filters(HasTagString::HasTagStringTag.all)
      ).
      paginate(page: params[:page], per_page: 50)
  end

  private

  def apply_filters(scope)
    @query = params[:query]
    return scope if @query.blank?

    name, value = HasTagString::HasTagStringTag.
      split_tag_into_name_value(@query)

    scope = scope.where('has_tag_string_tags.name LIKE ?', "%#{name}%") if name
    if value
      scope = scope.where('has_tag_string_tags.value LIKE ?', "%#{value}%")
    end

    scope
  end

  helper_method :current_klass
  def current_klass
    params.fetch(:model_type, 'PublicBody').safe_constantize
  end

  def check_klass
    raise RouteNotFound unless Taggable.models.include?(current_klass)
  end
end

class Admin::TagsController < AdminController
  include Admin::TagHelper

  before_action :check_klass
  before_action :find_instance, only: [:edit, :update]

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

    @notes = Note.distinct.where(notable_tag: @tag).
      paginate(page: params[:page], per_page: 50)

    @taggings = current_klass.with_tag(@tag).distinct.
      joins(:tags).merge(
        apply_filters(HasTagString::HasTagStringTag.all)
      ).
      paginate(page: params[:page], per_page: 50)
  end

  def edit
  end

  def update
    if @tag_instance.update(tag_params)
      redirect_to admin_tag_path(@tag, model_type: current_klass), notice: 'Tag was successfully updated.'
    else
      render :edit
    end
  end

  private

  def apply_filters(scope)
    @query = params[:query]
    return scope if @query.blank?

    name, value = HasTagString::HasTagStringTag.
      split_tag_into_name_value(@query)

    if @query.include?(':')
      scope = scope.where('has_tag_string_tags.name = ?', name) if name.present?
      if value.present?
        scope = scope.where('has_tag_string_tags.value LIKE ?', "#{value}%")
      end
    elsif name.present?
      scope = scope.where('has_tag_string_tags.name LIKE ?', "%#{name}%").or(
        scope.where('has_tag_string_tags.value LIKE ?', "%#{name}%")
      )
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

  def find_instance
    @tag = params.fetch(:tag)
    name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(@tag)

    @tag_instance = HasTagString::HasTagStringTag.find_by!(
      name: name,
      value: value
    )
  end

  def tag_params
    params.permit(:prominence, :prominence_reason)
  end
end

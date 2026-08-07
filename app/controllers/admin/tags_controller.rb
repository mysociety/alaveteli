class Admin::TagsController < AdminController
  include Admin::TagHelper

  before_action :check_klass

  skip_before_action :html_response, only: :list_for_widget

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

  # list available tags with their usage count for use in js widget
  def list_for_widget
    query = <<-SQL
    SELECT
      concat_ws(':',  name, value) AS t,
      COUNT(*) AS c
    FROM has_tag_string_tags
    GROUP BY (name, value)
    HAVING COUNT(*) > 1
    ORDER BY c DESC;
    SQL

    render json: ActiveRecord::Base.connection.execute(query)
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
end

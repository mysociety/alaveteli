##
# Display and administer categories
#
class Admin::CategoriesController < AdminController
  include TranslatableParams

  before_action :set_category, only: [:edit, :update, :destroy, :reorder]
  before_action :set_root, except: [:destroy, :reorder]
  before_action :check_klass

  def index
  end

  def show
    redirect_to action: :edit
  end

  def new
    @category = Category.new
    @category.build_all_translations
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = 'Category was successfully created.'
      redirect_to admin_categories_path(model_type: current_klass)
    else
      @category.build_all_translations
      render action: 'new'
    end
  end

  def edit
    @category.build_all_translations
  end

  def update
    if @category.update(category_params)
      flash[:notice] = 'Category was successfully updated.'
      redirect_to admin_categories_path(model_type: current_klass)
    else
      @category.build_all_translations
      render action: 'edit'
    end
  end

  def destroy
    @category.destroy
    flash[:notice] = 'Category was successfully destroyed.'
    redirect_to admin_categories_path(model_type: current_klass)
  end

  def reorder
    transaction = reorder_categories(params[:categories])
    if transaction[:success]
      head :ok
    else
      render plain: transaction[:error], status: :unprocessable_entity
    end
  end

  private

  def reorder_categories(category_ids)
    error = nil
    ActiveRecord::Base.transaction do
      category_ids.each_with_index do |id, index|
        CategoryRelationship.find_by!(parent_id: @category.id, child_id: id).
          update(position: index + 1)
      rescue ActiveRecord::RecordNotFound
        error = "Couldn't find Category #{id}"
        raise ActiveRecord::Rollback
      end
    end
    { success: error.nil?, error: error }
  end

  def category_params
    category_params = translatable_params(
      params.require(:category),
      translated_keys: [:locale, :title, :description],
      general_keys: [:category_tag, :parent_ids]
    )
    category_params[:parent_ids] ||= [@root.id]
    category_params
  end

  def set_category
    @category = Category.find(params[:id])
  end

  def set_root
    @root = current_klass&.category_root
  end

  helper_method :current_klass
  def current_klass
    @klass ||= @category.root.title.safe_constantize if @category&.root
    @klass ||= params.fetch(:model_type, 'PublicBody').safe_constantize
  end

  def check_klass
    raise RouteNotFound unless Categorisable.models.include?(current_klass)
  end
end

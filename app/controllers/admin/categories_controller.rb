##
# Display and administer categories
#
class Admin::CategoriesController < AdminController
  include TranslatableParams

  before_action :set_root, expect: [:destroy, :reorder]
  before_action :set_category, only: [:edit, :update, :destroy, :reorder]

  def index
  end

  def new
    @category = Category.new
    @category.build_all_translations
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = 'Category was successfully created.'
      redirect_to admin_categories_path
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
      redirect_to admin_categories_path
    else
      @category.build_all_translations
      render action: 'edit'
    end
  end

  def destroy
    @category.destroy
    flash[:notice] = 'Category was successfully destroyed.'
    redirect_to admin_categories_path
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

  def set_root
    @root = PublicBody.category_root
  end

  def set_category
    @category = Category.find(params[:id])
  end
end

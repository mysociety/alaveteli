# -*- encoding : utf-8 -*-
class AdminPublicBodyHeadingsController < AdminController

  def new
    @heading = PublicBodyHeading.new
    @heading.build_all_translations
  end

  def create
    I18n.with_locale(I18n.default_locale) do
      @heading = PublicBodyHeading.new(params[:public_body_heading])
      if @heading.save
        flash[:notice] = 'Heading was successfully created.'
        redirect_to admin_categories_url
      else
        @heading.build_all_translations
        render :action => 'new'
      end
    end
  end

  def edit
    @heading = PublicBodyHeading.find(params[:id])
    @heading.build_all_translations
  end

  def update
    @heading = PublicBodyHeading.find(params[:id])

    I18n.with_locale(I18n.default_locale) do
      if @heading.update_attributes(params[:public_body_heading])
        flash[:notice] = 'Heading was successfully updated.'
        redirect_to edit_admin_heading_path(@heading)
      else
        @heading.build_all_translations
        render :action => 'edit'
      end
    end
  end

  def destroy
    @locale = self.locale_from_params
    I18n.with_locale(@locale) do
      heading = PublicBodyHeading.find(params[:id])
      heading.destroy
      flash[:notice] = "Heading was successfully destroyed."
      redirect_to admin_categories_url
    end
  end

  def reorder
    transaction = reorder_headings(params[:headings])
    if transaction[:success]
      render :nothing => true, :status => :ok
    else
      render :text => transaction[:error], :status => :unprocessable_entity
    end
  end

  def reorder_categories
    transaction = reorder_categories_for_heading(params[:id], params[:categories])
    if transaction[:success]
      render :nothing => true, :status => :ok and return
    else
      render :text => transaction[:error], :status => :unprocessable_entity
    end
  end

  protected

  def reorder_headings(headings)
    error = nil
    ActiveRecord::Base.transaction do
      headings.each_with_index do |heading_id, index|
        begin
          heading = PublicBodyHeading.find(heading_id)
        rescue ActiveRecord::RecordNotFound => e
          error = e.message
          raise ActiveRecord::Rollback
        end
        heading.display_order = index
        unless heading.save
          error = heading.errors.full_messages.join(",")
          raise ActiveRecord::Rollback
        end
      end
    end
    { :success => error.nil?, :error => error }
  end

  def reorder_categories_for_heading(heading_id, categories)
    error = nil
    ActiveRecord::Base.transaction do
      categories.each_with_index do |category_id, index|
        conditions = { :public_body_category_id => category_id,
                       :public_body_heading_id => heading_id }
        link = PublicBodyCategoryLink.where(conditions).first
        unless link
          error = "Couldn't find PublicBodyCategoryLink for category #{category_id}, heading #{heading_id}"
          raise ActiveRecord::Rollback
        end
        link.category_display_order = index
        unless link.save
          error = link.errors.full_messages.join(",")
          raise ActiveRecord::Rollback
        end
      end
    end
    { :success => error.nil?, :error => error }
  end

end

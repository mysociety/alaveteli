# -*- encoding : utf-8 -*-
class AdminPublicBodyHeadingsController < AdminController

  before_filter :set_public_body_heading, :only => [:edit, :update, :destroy]

  def new
    @heading = PublicBodyHeading.new
    @heading.build_all_translations
  end

  def create
    I18n.with_locale(I18n.default_locale) do
      @heading = PublicBodyHeading.new(public_body_heading_params)
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
    @heading.build_all_translations
  end

  def update
    I18n.with_locale(I18n.default_locale) do
      if @heading.update_attributes(public_body_heading_params)
        flash[:notice] = 'Heading was successfully updated.'
        redirect_to edit_admin_heading_path(@heading)
      else
        @heading.build_all_translations
        render :action => 'edit'
      end
    end
  end

  def destroy
    @heading.destroy
    flash[:notice] = "Heading was successfully destroyed."
    redirect_to admin_categories_url
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

  private

  def public_body_heading_params
    if params[:public_body_heading]
      locale_keys = [:locale, :name]
      valid_keys = locale_keys + [:translations_attributes]
      public_body_heading_params = params[:public_body_heading].slice(*valid_keys)
      locale_keys << :id
      if translation_params = public_body_heading_params[:translations_attributes]
        translation_params.each do |locale, translations_attributes|
          translation_params[locale] = translations_attributes.slice(*locale_keys)
        end
      end
      public_body_heading_params
    else
      {}
    end
  end

  def set_public_body_heading
    @heading = PublicBodyHeading.find(params[:id])
  end

end

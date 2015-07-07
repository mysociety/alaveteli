# -*- encoding : utf-8 -*-
class AdminPublicBodyCategoriesController < AdminController
    def index
        @locale = self.locale_from_params
        @category_headings = PublicBodyHeading.all
        @without_heading = PublicBodyCategory.without_headings
    end

    def new
        @category = PublicBodyCategory.new
        @category.build_all_translations
    end

    def create
        I18n.with_locale(I18n.default_locale) do
            @category = PublicBodyCategory.new(params[:public_body_category])
            if @category.save
                # FIXME: This can't handle failure (e.g. if a PublicBodyHeading
                # doesn't exist)
                if params[:headings]
                    params[:headings].values.each do |heading_id|
                        PublicBodyHeading.find(heading_id).add_category(@category)
                    end
                end
                flash[:notice] = 'Category was successfully created.'
                redirect_to admin_categories_path
            else
                @category.build_all_translations
                render :action => 'new'
            end
        end
    end

    def edit
        @category = PublicBodyCategory.find(params[:id])
        @category.build_all_translations
        @tagged_public_bodies = PublicBody.find_by_tag(@category.category_tag)
    end

    def update
        @category = PublicBodyCategory.find(params[:id])
        @tagged_public_bodies = PublicBody.find_by_tag(@category.category_tag)

        heading_ids = []

        I18n.with_locale(I18n.default_locale) do
            if params[:public_body_category][:category_tag] && PublicBody.find_by_tag(@category.category_tag).count > 0 && @category.category_tag != params[:public_body_category][:category_tag]
                flash[:error] = "There are authorities associated with this category, so the tag can't be renamed"
                render :action => 'edit'
            else
                if params[:headings]
                    heading_ids = params[:headings].values
                    removed_headings = @category.public_body_heading_ids - heading_ids
                    added_headings = heading_ids - @category.public_body_heading_ids

                    unless removed_headings.empty?
                        # remove the link objects
                        deleted_links = PublicBodyCategoryLink.where(
                            :public_body_category_id => @category.id,
                            :public_body_heading_id => [removed_headings]
                        )
                        deleted_links.delete_all

                        #fix the category object
                        @category.public_body_heading_ids = heading_ids
                    end

                    added_headings.each do |heading_id|
                        # FIXME: This can't handle failure (e.g. if a
                        # PublicBodyHeading doesn't exist)
                        PublicBodyHeading.find(heading_id).add_category(@category)
                    end
                end

                if @category.update_attributes(params[:public_body_category])
                    flash[:notice] = 'Category was successfully updated.'
                    redirect_to edit_admin_category_path(@category)
                else
                    @category.build_all_translations
                    render :action => 'edit'
                end
            end
        end
    end

    def destroy
        @locale = self.locale_from_params
        I18n.with_locale(@locale) do
            category = PublicBodyCategory.find(params[:id])
            category.destroy
            flash[:notice] = "Category was successfully destroyed."
            redirect_to admin_categories_path
        end
    end
end

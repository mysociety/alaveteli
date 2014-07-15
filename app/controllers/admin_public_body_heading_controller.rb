class AdminPublicBodyHeadingController < AdminController
    def index
        redirect_to admin_category_index_url
    end

    def edit
        @heading = PublicBodyHeading.find(params[:id])
        render :formats => [:html]
    end

    def update
        I18n.with_locale(I18n.default_locale) do
            @heading = PublicBodyHeading.find(params[:id])
            if @heading.update_attributes(params[:public_body_heading])
                flash[:notice] = 'Category heading was successfully updated.'
            end
            render :action => 'edit'
        end
    end

    def new
        @heading = PublicBodyHeading.new
        render :formats => [:html]
    end

    def create
        I18n.with_locale(I18n.default_locale) do
            @heading = PublicBodyHeading.new(params[:public_body_heading])
            if @heading.save
                flash[:notice] = 'Category heading was successfully created.'
                redirect_to admin_category_index_url
            else
                render :action => 'new'
            end
        end
    end

    def destroy
        @locale = self.locale_from_params()
        I18n.with_locale(@locale) do
            heading = PublicBodyHeading.find(params[:id])

            if heading.public_body_categories.count > 0
                flash[:notice] = "There are categories associated with this heading, so can't destroy it"
                redirect_to admin_heading_edit_url(heading)
                return
            end

            heading.destroy
            flash[:notice] = "Category heading was successfully destroyed."
            redirect_to admin_category_index_url
        end
    end
end

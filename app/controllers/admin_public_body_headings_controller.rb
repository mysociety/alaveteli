class AdminPublicBodyHeadingsController < AdminController

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

    def reorder
        error = nil
        ActiveRecord::Base.transaction do
            params[:headings].each_with_index do |heading_id, index|
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
            render :nothing => true, :status => :ok and return
        end
        render :text => error, :status => :unprocessable_entity
    end

    def reorder_categories
        error = nil
        ActiveRecord::Base.transaction do
            params[:categories].each_with_index do |category_id, index|
                conditions = { :public_body_category_id => category_id,
                               :public_body_heading_id => params[:id] }
                link = PublicBodyCategoryLink.where(conditions).first
                unless link
                    error = "Couldn't find PublicBodyCategoryLink for category #{category_id}, heading #{params[:id]}"
                    raise ActiveRecord::Rollback
                end
                link.category_display_order = index
                unless link.save
                    error = link.errors.full_messages.join(",")
                    raise ActiveRecord::Rollback
                end
            end
            render :nothing => true, :status => :ok and return
        end
        render :text => error, :status => :unprocessable_entity
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
                redirect_to categories_url
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
                redirect_to edit_heading_url(heading)
                return
            end

            heading.destroy
            flash[:notice] = "Category heading was successfully destroyed."
            redirect_to categories_url
        end
    end
end

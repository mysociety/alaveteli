# app/controllers/admin_public_body_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_public_body_controller.rb,v 1.23 2009-08-26 00:58:29 francis Exp $

require "public_body_categories"

class AdminPublicBodyController < AdminController
    def index
        list
        render :action => 'list'
    end

    def _lookup_query_internal
        @locale = self.locale_from_params()
        PublicBody.with_locale(@locale) do 
            @query = params[:query]
            if @query == ""
                @query = nil
            end
            @page = params[:page]
            if @page == ""
                @page = nil
            end
            @public_bodies = PublicBody.paginate :order => "public_body_translations.name", :page => @page, :per_page => 100,
                :conditions =>  @query.nil? ? "public_body_translations.locale = '#{@locale}'" : 
                                ["(lower(public_body_translations.name) like lower('%'||?||'%') or 
                                 lower(public_body_translations.short_name) like lower('%'||?||'%') or 
                                 lower(public_body_translations.request_email) like lower('%'||?||'%' )) AND (public_body_translations.locale = '#{@locale}')", @query, @query, @query],
              :joins => :translations
        end
        @public_bodies_by_tag = PublicBody.find_by_tag(@query) 
    end

    def list
        self._lookup_query_internal
    end

    def mass_tag_add
        self._lookup_query_internal

        if params[:new_tag] and params[:new_tag] != ""
            if params[:table_name] == 'exact'
                bodies = @public_bodies_by_tag
            elsif params[:table_name] == 'substring'
                bodies = @public_bodies
            else
                raise "Unknown table_name " + params[:table_name]
            end
            for body in bodies
                body.add_tag_if_not_already_present(params[:new_tag])
            end
            flash[:notice] = "Added tag to table of bodies."
        end

        redirect_to admin_body_list_url(:query => @query, :page => @page)
    end

    def missing_scheme
        # There might be a way to do this in ActiveRecord, but I can't find it
        @public_bodies = PublicBody.find_by_sql("
            SELECT a.id, a.name, a.url_name, COUNT(*) AS howmany 
              FROM public_bodies a JOIN info_requests r ON a.id = r.public_body_id 
             WHERE a.publication_scheme = '' 
             GROUP BY a.id, a.name, a.url_name 
             ORDER BY howmany DESC 
             LIMIT 20
        ")
        @stats = {
          "total" => PublicBody.count,
          "entered" => PublicBody.count(:conditions => "publication_scheme != ''")
        }
    end

    def show
        @locale = self.locale_from_params()
        PublicBody.with_locale(@locale) do 
            @public_body = PublicBody.find(params[:id])
            render
        end
    end

    def new
        @public_body = PublicBody.new
        render
    end
    
    def create
        PublicBody.with_locale(I18n.default_locale) do
            params[:public_body][:last_edit_editor] = admin_http_auth_user()
            @public_body = PublicBody.new(params[:public_body])
            if @public_body.save
                flash[:notice] = 'PublicBody was successfully created.'
                redirect_to admin_url('body/show/' + @public_body.id.to_s)
            else
                render :action => 'new'
            end
        end
    end

    def edit
        @public_body = PublicBody.find(params[:id])
        @public_body.last_edit_comment = ""        
        render
    end

    def update
        PublicBody.with_locale(I18n.default_locale) do
            params[:public_body][:last_edit_editor] = admin_http_auth_user()
            @public_body = PublicBody.find(params[:id])
            if @public_body.update_attributes(params[:public_body])
                flash[:notice] = 'PublicBody was successfully updated.'
                redirect_to admin_url('body/show/' + @public_body.id.to_s)
            else
                render :action => 'edit'
            end
        end
    end

    def destroy
        @locale = self.locale_from_params()
        PublicBody.with_locale(@locale) do 
            public_body = PublicBody.find(params[:id])

            if public_body.info_requests.size > 0
                flash[:notice] = "There are requests associated with the authority, so can't destroy it"
                redirect_to admin_body_show_url(public_body)
                return
            end

            public_body.tag_string = ""
            public_body.destroy
            flash[:notice] = "PublicBody was successfully destroyed."
            redirect_to admin_body_list_url
        end
    end

    def import_csv
        if params[:csv_file]
            if params['commit'] == 'Dry run'
                dry_run_only = true
            elsif params['commit'] == 'Upload'
                dry_run_only = false
            else
                raise "internal error, unknown button label"
            end
            
            # Try with dry run first
            csv_contents = params[:csv_file].read
            en = PublicBody.import_csv(csv_contents, params[:tag], params[:tag_behaviour], true, admin_http_auth_user(), I18n.available_locales)
            errors = en[0]
            notes = en[1]

            if errors.size == 0
                if dry_run_only
                    notes.push("Dry run was successful, real run would do as above.")
                else
                    # And if OK, with real run
                    en = PublicBody.import_csv(csv_contents, params[:tag], params[:tag_behaviour], false, admin_http_auth_user(), I18n.available_locales)
                    errors = en[0]
                    notes = en[1]
                    if errors.size != 0
                        raise "dry run mismatched real run"
                    end
                    notes.push("Import was successful.")
                end
            end
            @errors = errors.join("\n")
            @notes = notes.join("\n")
        else
            @errors = ""
            @notes = ""
        end
        
    end

    private

end

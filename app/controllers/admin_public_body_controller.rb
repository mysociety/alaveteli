# app/controllers/admin_public_body_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_public_body_controller.rb,v 1.14 2008-05-21 22:37:32 francis Exp $

class AdminPublicBodyController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

    def index
        list
        render :action => 'list'
    end

    def list
        @query = params[:query]
        @public_bodies = PublicBody.paginate :order => "name", :page => params[:page], :per_page => 100,
            :conditions =>  @query.nil? ? nil : ["name ilike '%'||?||'%' or 
                             short_name ilike '%'||?||'%' or 
                             request_email ilike '%'||?||'%'", @query, @query, @query]
    end

    def show
        @public_body = PublicBody.find(params[:id])
    end

    def new
        @public_body = PublicBody.new
    end

    def create
        params[:public_body][:last_edit_editor] = admin_http_auth_user()
        @public_body = PublicBody.new(params[:public_body])
        if @public_body.save
            flash[:notice] = 'PublicBody was successfully created.'
            redirect_to admin_url('body/show/' + @public_body.id.to_s)
        else
            render :action => 'new'
        end
    end

    def edit
        @public_body = PublicBody.find(params[:id])
        @public_body.last_edit_comment = ""
    end

    def update
        params[:public_body][:last_edit_editor] = admin_http_auth_user()
        @public_body = PublicBody.find(params[:id])
        if @public_body.update_attributes(params[:public_body])
            flash[:notice] = 'PublicBody was successfully updated.'
            redirect_to admin_url('body/show/' + @public_body.id.to_s)
        else
            render :action => 'edit'
        end
    end

    def destroy
        public_body = PublicBody.find(params[:id])
        public_body.tag_string = ""
        public_body.destroy
        flash[:notice] = "PublicBody was successfully destroyed."
        redirect_to admin_url('body/list')
    end

    def import_csv
        if params[:csv_file]
            if not params[:tag].empty?
                # Try with dry run first
                csv_contents = params[:csv_file].read
                en = PublicBody.import_csv(csv_contents, params[:tag], true, admin_http_auth_user())
                errors = en[0]
                notes = en[1]

                if errors.size == 0
                    # And if OK, with real run
                    en = PublicBody.import_csv(csv_contents, params[:tag], false, admin_http_auth_user())
                    errors = en[0]
                    notes = en[1]
                    if errors.size != 0
                        raise "dry run mismatched real run"
                    end
                    notes.push("Import was successful.")
                end
                @errors = errors.join("\n")
                @notes = notes.join("\n")
            else
                @errors = "Please enter a tag, use a singular e.g. sea_fishery_committee"
                @notes = ""
            end
        else
            @errors = ""
            @notes = ""
        end
        
    end

    private

end

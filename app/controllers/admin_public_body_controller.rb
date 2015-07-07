# -*- encoding : utf-8 -*-
# app/controllers/admin_public_body_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminPublicBodyController < AdminController

    def index
        lookup_query
    end

    def show
        @locale = locale_from_params
        I18n.with_locale(@locale) do
            @public_body = PublicBody.find(params[:id])
            @info_requests = @public_body.info_requests.paginate :order => "created_at desc",
                                                                 :page => params[:page],
                                                                 :per_page => 100
            render
        end
    end

    def new
        @public_body = PublicBody.new
        @public_body.build_all_translations

        if params[:change_request_id]
            @change_request = PublicBodyChangeRequest.find(params[:change_request_id])
        end
        if @change_request
            @change_request_user_response = render_to_string(:template => "admin_public_body_change_requests/add_accepted",
                                                             :formats => [:txt])
            @public_body.name = @change_request.public_body_name
            @public_body.request_email = @change_request.public_body_email
            @public_body.last_edit_comment = @change_request.comment_for_public_body
        end
        render :formats => [:html]
    end

    def create
        I18n.with_locale(I18n.default_locale) do
            if params[:change_request_id]
                @change_request = PublicBodyChangeRequest.find(params[:change_request_id])
            end
            params[:public_body][:last_edit_editor] = admin_current_user
            @public_body = PublicBody.new(params[:public_body])
            if @public_body.save
               if @change_request
                    response_text = params[:response].gsub(_("[Authority URL will be inserted here]"),
                                                          public_body_url(@public_body, :only_path => false))
                    @change_request.close!
                    @change_request.send_response(params[:subject], response_text)
                end
                flash[:notice] = 'PublicBody was successfully created.'
                redirect_to admin_body_url(@public_body)
            else
                @public_body.build_all_translations
                render :action => 'new'
            end
        end
    end

    def edit
        @public_body = PublicBody.find(params[:id])
        @public_body.build_all_translations

        if params[:change_request_id]
            @change_request = PublicBodyChangeRequest.find(params[:change_request_id])
        end
        if @change_request
            @change_request_user_response = render_to_string(:template => "admin_public_body_change_requests/update_accepted",
                                                             :formats => [:txt])
            @public_body.request_email = @change_request.public_body_email
            @public_body.last_edit_comment = @change_request.comment_for_public_body
        else
            @public_body.last_edit_comment = ""
        end
        render :formats => [:html]
    end

    def update
        if params[:change_request_id]
            @change_request = PublicBodyChangeRequest.find(params[:change_request_id])
        end
        I18n.with_locale(I18n.default_locale) do
            params[:public_body][:last_edit_editor] = admin_current_user
            @public_body = PublicBody.find(params[:id])
            if @public_body.update_attributes(params[:public_body])
                if @change_request
                    @change_request.close!
                    @change_request.send_response(params[:subject], params[:response])
                end
                flash[:notice] = 'PublicBody was successfully updated.'
                redirect_to admin_body_url(@public_body)
            else
                @public_body.build_all_translations
                render :action => 'edit'
            end
        end
    end

    def destroy
        @locale = locale_from_params
        I18n.with_locale(@locale) do
            public_body = PublicBody.find(params[:id])

            if public_body.info_requests.size > 0
                flash[:notice] = "There are requests associated with the authority, so can't destroy it"
                redirect_to admin_body_url(public_body)
                return
            end

            public_body.tag_string = ""
            public_body.destroy
            flash[:notice] = "PublicBody was successfully destroyed."
            redirect_to admin_bodies_url
        end
    end

    def mass_tag_add
        lookup_query

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

        redirect_to admin_bodies_url(:query => @query, :page => @page)
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

    def import_csv
        @notes = ""
        @errors = ""
        if request.post?
            dry_run_only = params['commit'] != 'Upload'
            # (FIXME: both of these cases could now be changed to use
            # PublicBody.import_csv_from_file.)
            # Read file from params
            if params[:csv_file]
                csv_contents = params[:csv_file].read
                @original_csv_file = params[:csv_file].original_filename
                csv_contents = normalize_string_to_utf8(csv_contents)
            # or from previous dry-run temporary file
            elsif params[:temporary_csv_file] && params[:original_csv_file]
                csv_contents = retrieve_csv_data(params[:temporary_csv_file])
                @original_csv_file = params[:original_csv_file]
            end
            if !csv_contents.nil?
                # Try with dry run first
                errors, notes = PublicBody.import_csv(csv_contents,
                                                      params[:tag],
                                                      params[:tag_behaviour],
                                                      true,
                                                      admin_current_user,
                                                      I18n.available_locales)

                if errors.size == 0
                    if dry_run_only
                        notes.push("Dry run was successful, real run would do as above.")
                        # Store the csv file for ease of performing the real run
                        @temporary_csv_file = store_csv_data(csv_contents)
                    else
                        # And if OK, with real run
                        errors, notes = PublicBody.import_csv(csv_contents,
                                                              params[:tag],
                                                              params[:tag_behaviour],
                                                              false,
                                                              admin_current_user,
                                                              I18n.available_locales)
                        if errors.size != 0
                            raise "dry run mismatched real run"
                        end
                        notes.push("Import was successful.")
                    end
                end
                @errors = errors.join("\n")
                @notes = notes.join("\n")
            end
        end
    end

    private

    # Save the contents to a temporary file - not using Tempfile as we need
    # the file to persist between requests. Return the name of the file.
    def store_csv_data(csv_contents)
        tempfile_name = "csv_upload-#{Time.now.strftime("%Y%m%d")}-#{SecureRandom.random_number(10000)}"
        tempfile = File.new(File.join(Dir::tmpdir, tempfile_name), 'w')
        tempfile.write(csv_contents)
        tempfile.close
        return tempfile_name
    end

    # Get csv contents from the file whose name is passed, as long as the
    # name is of the expected form.
    # Delete the file, return the contents.
    def retrieve_csv_data(tempfile_name)
        if not /csv_upload-\d{8}-\d{1,5}/.match(tempfile_name)
            raise "Invalid filename in upload_csv: #{tempfile_name}"
        end
        tempfile_path = File.join(Dir::tmpdir, tempfile_name)
        if ! File.exist?(tempfile_path)
            raise "Missing file in upload_csv: #{tempfile_name}"
        end
        csv_contents = File.read(tempfile_path)
        File.delete(tempfile_path)
        return csv_contents
    end

    def lookup_query
        @locale = locale_from_params
        underscore_locale = @locale.gsub '-', '_'
        I18n.with_locale(@locale) do
            @query = params[:query]
            if @query == ""
                @query = nil
            end
            @page = params[:page]
            if @page == ""
                @page = nil
            end
            @public_bodies = PublicBody.joins(:translations).where(@query.nil? ? "public_body_translations.locale = '#{underscore_locale}'" :
                                ["(lower(public_body_translations.name) like lower('%'||?||'%') or
                                 lower(public_body_translations.short_name) like lower('%'||?||'%') or
                                 lower(public_body_translations.request_email) like lower('%'||?||'%' )) AND (public_body_translations.locale = '#{underscore_locale}')", @query, @query, @query]).paginate :order => "public_body_translations.name", :page => @page, :per_page => 100
        end
        @public_bodies_by_tag = PublicBody.find_by_tag(@query)
    end

end

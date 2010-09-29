# app/controllers/public_body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_controller.rb,v 1.8 2009-09-14 13:27:00 francis Exp $

require 'csv'

class PublicBodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        if MySociety::Format.simplify_url_part(params[:url_name], 'body') != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 'body'), :status => :moved_permanently 
            return
        end

        @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
        raise "None found" if @public_body.nil? # XXX proper 404

        # If found by historic name, redirect to new name
        redirect_to show_public_body_url(:url_name => @public_body.url_name) if 
            @public_body.url_name != params[:url_name]

        set_last_body(@public_body)

        top_url = main_url("/")
        @searched_to_send_request = false
        referrer = request.env['HTTP_REFERER']
        if !referrer.nil? && referrer.match(%r{^#{top_url}search/.*/bodies$})
            @searched_to_send_request = true
        end

        # Use search query for this so can collapse and paginate easily
        # XXX really should just use SQL query here rather than Xapian.
        begin
            @xapian_requests = perform_search([InfoRequestEvent], 'requested_from:' + @public_body.url_name, 'newest', 'request_collapse')
            if (@page > 1)
                @page_desc = " (page " + @page.to_s + ")" 
            else    
                @page_desc = ""
            end
        rescue
            @xapian_requests = nil
        end

        @track_thing = TrackThing.create_track_for_public_body(@public_body)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
    end

    def view_email
        @public_bodies = PublicBody.find(:all, :conditions => [ "url_name = ?", params[:url_name] ])
        @public_body = @public_bodies[0]

        if params[:submitted_view_email]
            if verify_recaptcha
                flash.discard(:error)
                render :template => "public_body/view_email"
                return
            end
            flash.now[:error] = "There was an error with the words you entered, please try again."
        end
        render :template => "public_body/view_email_captcha"
    end

    def list
        # XXX move some of these tag SQL queries into has_tag_string.rb
        @tag = params[:tag]
        if @tag.nil?
            @tag = "all"
            conditions = []
        elsif @tag == 'other'
            category_list = PublicBodyCategories::CATEGORIES.map{|c| "'"+c+"'"}.join(",")
            conditions = ['(select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name in (' + category_list + ')) = 0']
        elsif @tag.size == 1
            @tag.upcase!
            conditions = ['first_letter = ?', @tag]
        elsif @tag.include?(":")
            name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(@tag)
            conditions = ['(select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name = ? and has_tag_string_tags.value = ?) > 0', name, value]
        else
            conditions = ['(select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name = ?) > 0', @tag]
        end
        @public_bodies = PublicBody.paginate(
            :order => "public_bodies.name", :page => params[:page], :per_page => 1000, # fit all councils on one page
            :conditions => conditions
            )
        if @tag.size == 1
            @description = "beginning with '" + @tag + "'"
        else
            @description = PublicBodyCategories::CATEGORIES_BY_TAG[@tag]
            if @description.nil?
                @description = @tag
            end
        end
    end

    # Used so URLs like /local/islington work, for use e.g. writing to a local paper.
    def list_redirect
        @tag = params[:tag]
        redirect_to list_public_bodies_url(:tag => @tag)
    end

    def list_all_csv
        public_bodies = PublicBody.find(:all, :order => 'url_name')
        report = StringIO.new
        CSV::Writer.generate(report, ',') do |title|
            title << [
                    'Name', 
                    'Short name',
                    # deliberately not including 'Request email'
                    'URL name', 
                    'Tags',
                    'Home page',
                    'Publication scheme',
                    'Created at',
                    'Updated at',
                    'Version',
            ]
            public_bodies.each do |public_body|
                title << [ 
                    public_body.name, 
                    public_body.short_name, 
                    # DO NOT include request_email (we don't want to make it
                    # easy to spam all authorities with requests)
                    public_body.url_name, 
                    public_body.tag_string,
                    public_body.calculated_home_page,
                    public_body.publication_scheme,
                    public_body.created_at,
                    public_body.updated_at,
                    public_body.version,
                ]
            end
        end
        report.rewind
        send_data(report.read, :type=> 'text/csv; charset=utf-8; header=present',
                  :filename => 'all-authorities.csv', 
                  :disposition =>'attachment', :encoding => 'utf8')
    end
end


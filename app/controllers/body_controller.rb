# app/controllers/body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: body_controller.rb,v 1.25 2009-03-24 13:05:01 tony Exp $

class BodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        if MySociety::Format.simplify_url_part(params[:url_name]) != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name])
            return
        end

        @public_body = PublicBody.find_by_urlname(params[:url_name])
        raise "None found" if @public_body.nil? # XXX proper 404

        # If found by historic name, redirect to new name
        redirect_to show_public_body_url(:url_name => @public_body.url_name) if 
            @public_body.url_name != params[:url_name]

        set_last_body(@public_body)

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
                render :template => "body/view_email"
                return
            end
            flash.now[:error] = "There was an error with the words you entered, please try again."
        end
        render :template => "body/view_email_captcha"
    end

    def list
        @tag = params[:tag]
        if @tag.nil?
            @tag = "all"
            conditions = []
        elsif @tag == 'other'
            category_list = PublicBody.categories.map{|c| "'"+c+"'"}.join(",")
            conditions = ['(select count(*) from public_body_tags where public_body_tags.public_body_id = public_bodies.id
                and public_body_tags.name in (' + category_list + ')) = 0']
        elsif @tag.size == 1
            @tag.upcase!
            conditions = ['first_letter = ?', @tag]
        else
            conditions = ['(select count(*) from public_body_tags where public_body_tags.public_body_id = public_bodies.id
                and public_body_tags.name = ?) > 0', @tag]
        end
        @public_bodies = PublicBody.paginate(
            :order => "public_bodies.name", :page => params[:page], :per_page => 1000, # fit all councils on one page
            :conditions => conditions
            )
        if @tag.size == 1
            @description = "beginning with '" + @tag + "'"
        else
            @description = PublicBody.categories_by_tag[@tag]
            if @description.nil?
                @description = @tag
            end
        end
    end
end


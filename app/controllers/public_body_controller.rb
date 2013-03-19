# -*- coding: utf-8 -*-
# app/controllers/public_body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

require 'fastercsv'

class PublicBodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        long_cache
        if MySociety::Format.simplify_url_part(params[:url_name], 'body') != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 'body'), :status => :moved_permanently
            return
        end
        @locale = self.locale_from_params()
        PublicBody.with_locale(@locale) do
            @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
            raise ActiveRecord::RecordNotFound.new("None found") if @public_body.nil?
            if @public_body.url_name.nil?
                redirect_to :back
                return
            end
            # If found by historic name, or alternate locale name, redirect to new name
            if  @public_body.url_name != params[:url_name]
                redirect_to :url_name => @public_body.url_name
                return
            end

            set_last_body(@public_body)

            top_url = frontpage_url
            @searched_to_send_request = false
            referrer = request.env['HTTP_REFERER']
            if !referrer.nil? && referrer.match(%r{^#{top_url}search/.*/bodies$})
                @searched_to_send_request = true
            end
            @view = params[:view]
            query = make_query_from_params(params.merge(:latest_status => @view))
            query += " requested_from:#{@public_body.url_name}"
            # Use search query for this so can collapse and paginate easily
            # XXX really should just use SQL query here rather than Xapian.
            sortby = "described"
            begin
                @xapian_requests = perform_search([InfoRequestEvent], query, sortby, 'request_collapse')
                if (@page > 1)
                    @page_desc = " (page " + @page.to_s + ")"
                else
                    @page_desc = ""
                end
            rescue
                @xapian_requests = nil
            end

            @track_thing = TrackThing.create_track_for_public_body(@public_body)
            @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

            respond_to do |format|
                format.html { @has_json = true; render :template => "public_body/show"}
                format.json { render :json => @public_body.json_for_api }
            end

        end
    end

    def view_email
        @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
        raise ActiveRecord::RecordNotFound.new("None found") if @public_body.nil?

        PublicBody.with_locale(self.locale_from_params()) do
            if params[:submitted_view_email]
                if verify_recaptcha
                    flash.discard(:error)
                    render :template => "public_body/view_email"
                    return
                end
                flash.now[:error] = _("There was an error with the words you entered, please try again.")
            end
            render :template => "public_body/view_email_captcha"
        end
    end

    def list
        long_cache
        # XXX move some of these tag SQL queries into has_tag_string.rb
        @query = "%#{params[:public_body_query].nil? ? "" : params[:public_body_query]}%"
        @tag = params[:tag]
        @locale = self.locale_from_params()
        default_locale = I18n.default_locale.to_s
        locale_condition = "(upper(public_body_translations.name) LIKE upper(?)
                            OR upper(public_body_translations.notes) LIKE upper (?))
                            AND public_body_translations.locale = ?
                            AND public_bodies.id <> #{PublicBody.internal_admin_body.id}"
        if @tag.nil? or @tag == "all"
            @tag = "all"
            conditions = [locale_condition, @query, @query, default_locale]
        elsif @tag == 'other'
            category_list = PublicBodyCategories::get().tags().map{|c| "'"+c+"'"}.join(",")
            conditions = [locale_condition + ' AND (select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name in (' + category_list + ')) = 0', @query, @query, default_locale]
        elsif @tag.size == 1
            @tag.upcase!
            conditions = [locale_condition + ' AND public_body_translations.first_letter = ?', @query, @query, default_locale, @tag]
        elsif @tag.include?(":")
            name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(@tag)
            conditions = [locale_condition + ' AND (select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name = ? and has_tag_string_tags.value = ?) > 0', @query, @query, default_locale, name, value]
        else
            conditions = [locale_condition + ' AND (select count(*) from has_tag_string_tags where has_tag_string_tags.model_id = public_bodies.id
                and has_tag_string_tags.model = \'PublicBody\'
                and has_tag_string_tags.name = ?) > 0', @query, @query, default_locale, @tag]
        end

        if @tag == "all"
            @description = ""
        elsif @tag.size == 1
            @description = _("beginning with ‘{{first_letter}}’", :first_letter=>@tag)
        else
            category_name = PublicBodyCategories::get().by_tag()[@tag]
            if category_name.nil?
                @description = _("matching the tag ‘{{tag_name}}’", :tag_name=>@tag)
            else
                @description = _("in the category ‘{{category_name}}’", :category_name=>category_name)
            end
        end
        PublicBody.with_locale(@locale) do
            @public_bodies = PublicBody.paginate(
              :order => "public_body_translations.name", :page => params[:page], :per_page => 100,
              :conditions => conditions,
              :joins => :translations
            )
            render :template => "public_body/list"
        end
    end

    # Used so URLs like /local/islington work, for use e.g. writing to a local paper.
    def list_redirect
        @tag = params[:tag]
        redirect_to list_public_bodies_url(:tag => @tag)
    end

    def list_all_csv
        send_data(PublicBody.export_csv, :type=> 'text/csv; charset=utf-8; header=present',
                  :filename => 'all-authorities.csv',
                  :disposition =>'attachment', :encoding => 'utf8')
    end

    # Type ahead search
    def search_typeahead
        # Since acts_as_xapian doesn't support the Partial match flag, we work around it
        # by making the last work a wildcard, which is quite the same
        query = params[:query]
        @xapian_requests = perform_search_typeahead(query, PublicBody)
        render :partial => "public_body/search_ahead"
    end
end


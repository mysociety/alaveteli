# -*- coding: utf-8 -*-
# app/controllers/public_body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'fastercsv'
require 'confidence_intervals'

class PublicBodyController < ApplicationController
    # XXX tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
    def show
        long_cache
        if MySociety::Format.simplify_url_part(params[:url_name], 'body') != params[:url_name]
            redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 'body'), :status => :moved_permanently
            return
        end
        @locale = self.locale_from_params()
        I18n.with_locale(@locale) do
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

        I18n.with_locale(self.locale_from_params()) do
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

        like_query = params[:public_body_query]
        like_query = "" if like_query.nil?
        like_query = "%#{like_query}%"

        @tag = params[:tag]

        @locale = self.locale_from_params
        underscore_locale = @locale.gsub '-', '_'
        underscore_default_locale = I18n.default_locale.to_s.gsub '-', '_'

        where_condition = "public_bodies.id <> #{PublicBody.internal_admin_body.id}"
        where_parameters = []

        first_letter = false

        base_tag_condition = " AND (SELECT count(*) FROM has_tag_string_tags" \
            " WHERE has_tag_string_tags.model_id = public_bodies.id" \
            " AND has_tag_string_tags.model = 'PublicBody'"

        # Restrict the public bodies shown according to the tag
        # parameter supplied in the URL:
        if @tag.nil? or @tag == "all"
            @tag = "all"
        elsif @tag == 'other'
            category_list = PublicBodyCategories::get().tags().map{|c| "'"+c+"'"}.join(",")
            where_condition += base_tag_condition + " AND has_tag_string_tags.name in (#{category_list})) = 0"
        elsif @tag.size == 1
            @tag.upcase!
            # The first letter queries have to be done on
            # translations, so just indicate to add that later:
            first_letter = true
        elsif @tag.include?(":")
            name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(@tag)
            where_condition += base_tag_condition + " AND has_tag_string_tags.name = ? AND has_tag_string_tags.value = ?) > 0"
            where_parameters.concat [name, value]
        else
            where_condition += base_tag_condition + " AND has_tag_string_tags.name = ?) > 0"
            where_parameters.concat [@tag]
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

        I18n.with_locale(@locale) do

            if AlaveteliConfiguration::public_body_list_fallback_to_default_locale
                # Unfortunately, when we might fall back to the
                # default locale, this is a rather complex query:
                query =  %Q{
                    SELECT public_bodies.*, COALESCE(current_locale.name, default_locale.name) AS display_name
                    FROM public_bodies
                    LEFT OUTER JOIN public_body_translations as current_locale
                        ON (public_bodies.id = current_locale.public_body_id
                            AND current_locale.locale = ? AND #{get_public_body_list_translated_condition 'current_locale', first_letter})
                    LEFT OUTER JOIN public_body_translations as default_locale
                        ON (public_bodies.id = default_locale.public_body_id
                            AND default_locale.locale = ? AND #{get_public_body_list_translated_condition 'default_locale', first_letter})
                    WHERE #{where_condition} AND COALESCE(current_locale.name, default_locale.name) IS NOT NULL
                    ORDER BY display_name}
                sql = [query, underscore_locale, like_query, like_query]
                sql.push @tag if first_letter
                sql += [underscore_default_locale, like_query, like_query]
                sql.push @tag if first_letter
                sql += where_parameters
                @public_bodies = PublicBody.paginate_by_sql(
                    sql,
                    :page => params[:page],
                    :per_page => 100)
            else
                # The simpler case where we're just searching in the current locale:
                where_condition = get_public_body_list_translated_condition('public_body_translations', first_letter, true) +
                    ' AND ' + where_condition
                where_sql = [where_condition, like_query, like_query]
                where_sql.push @tag if first_letter
                where_sql += [underscore_locale] + where_parameters
                @public_bodies = PublicBody.where(where_sql) \
                    .joins(:translations) \
                    .order("public_body_translations.name") \
                    .paginate(:page => params[:page], :per_page => 100)
            end

            respond_to do |format|
                format.html { render :template => "public_body/list" }
            end
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

    def statistics
        unless AlaveteliConfiguration::public_body_statistics_page
            raise ActiveRecord::RecordNotFound.new("Page not enabled")
        end

        per_graph = 8
        minimum_requests = AlaveteliConfiguration::minimum_requests_for_statistics
        # Make sure minimum_requests is > 0 to avoid division-by-zero
        minimum_requests = [minimum_requests, 1].max
        total_column = 'info_requests_count'

        @graph_list = []

        [[total_column,
          [{
               :title => _('Public bodies with the most requests'),
               :y_axis => _('Number of requests'),
               :highest => true}]],
         ['info_requests_successful_count',
          [{
               :title => _('Public bodies with the most successful requests'),
               :y_axis => _('Percentage of total requests'),
               :highest => true},
           {
               :title => _('Public bodies with the fewest successful requests'),
               :y_axis => _('Percentage of total requests'),
               :highest => false}]],
         ['info_requests_overdue_count',
          [{
               :title => _('Public bodies with most overdue requests'),
               :y_axis => _('Percentage of requests that are overdue'),
               :highest => true}]],
         ['info_requests_not_held_count',
          [{
               :title => _('Public bodies that most frequently replied with "Not Held"'),
               :y_axis => _('Percentage of total requests'),
               :highest => true}]]].each do |column, graphs_properties|

            graphs_properties.each do |graph_properties|

                percentages = (column != total_column)
                highest = graph_properties[:highest]

                data = nil
                if percentages
                    data = PublicBody.get_request_percentages(column,
                                                              per_graph,
                                                              highest,
                                                              minimum_requests)
                else
                    data = PublicBody.get_request_totals(per_graph,
                                                         highest,
                                                         minimum_requests)
                end

                data_to_draw = {
                    'id' => "#{column}-#{highest ? 'highest' : 'lowest'}",
                    'x_axis' => _('Public Bodies'),
                    'y_axis' => graph_properties[:y_axis],
                    'errorbars' => percentages,
                    'title' => graph_properties[:title]}

                if data
                    data_to_draw.update(data)
                    data_to_draw['x_values'] = data['public_bodies'].each_with_index.map { |pb, i| i }
                    data_to_draw['x_ticks'] = data['public_bodies'].each_with_index.map { |pb, i| [i, pb.name] }
                end

                @graph_list.push data_to_draw
            end
        end

        respond_to do |format|
            format.html { render :template => "public_body/statistics" }
            format.json { render :json => @graph_list }
        end
    end

    # Type ahead search
    def search_typeahead
        # Since acts_as_xapian doesn't support the Partial match flag, we work around it
        # by making the last work a wildcard, which is quite the same
        query = params[:query]
        @xapian_requests = perform_search_typeahead(query, PublicBody)
        render :partial => "public_body/search_ahead"
    end

    private
    def get_public_body_list_translated_condition(table, first_letter=false, locale=nil)
        result = "(upper(#{table}.name) LIKE upper(?)" \
            " OR upper(#{table}.notes) LIKE upper (?))"
        if first_letter
            result += " AND #{table}.first_letter = ?"
        end
        if locale
            result += " AND #{table}.locale = ?"
        end
        result
    end

end

# -*- encoding : utf-8 -*-
# app/controllers/public_body_controller.rb:
# Show information about a public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'tempfile'

class PublicBodyController < ApplicationController

  MAX_RESULTS = 500
  # TODO: tidy this up with better error messages, and a more standard infrastructure for the redirect to canonical URL
  def show
    long_cache
    @page = get_search_page_from_params
    requests_per_page = 25

    # Later pages are very expensive to load
    if @page > MAX_RESULTS / requests_per_page
      raise ActiveRecord::RecordNotFound.new("Sorry. No pages after #{MAX_RESULTS / requests_per_page}.")
    end

    if MySociety::Format.simplify_url_part(params[:url_name], 'body') != params[:url_name]
      redirect_to :url_name =>  MySociety::Format.simplify_url_part(params[:url_name], 'body'), :status => :moved_permanently
      return
    end

    @locale = AlaveteliLocalization.locale

    AlaveteliLocalization.with_locale(@locale) do
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

      @number_of_visible_requests = @public_body.info_requests.is_searchable.count

      @searched_to_send_request = false
      referrer = request.env['HTTP_REFERER']

      if !referrer.nil? && referrer.match(%r{^#{frontpage_url}search/.*/bodies$})
        @searched_to_send_request = true
      end

      @view = params[:view]

      query = InfoRequestEvent.make_query_from_params(params.merge(:latest_status => @view))
      query += " requested_from:#{@public_body.url_name}"

      # Use search query for this so can collapse and paginate easily
      # TODO: really should just use SQL query here rather than Xapian.
      sortby = "described"
      begin
        @xapian_requests = perform_search([InfoRequestEvent], query, sortby, 'request_collapse', requests_per_page)
        if (@page > 1)
          @page_desc = " (page #{ @page })"
        else
          @page_desc = ""
        end
      rescue
        @xapian_requests = nil
      end

      flash.keep(:search_params)

      @track_thing = TrackThing.create_track_for_public_body(@public_body)

      if @user
        @existing_track = TrackThing.find_existing(@user, @track_thing)
      end

      @follower_count = TrackThing.where(:public_body_id => @public_body.id).count

      @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'),
                             :title => @track_thing.params[:title_in_rss],
                             :has_json => true } ]

      respond_to do |format|
        format.html { @has_json = true; render :template => "public_body/show"}
        format.json { render :json => @public_body.json_for_api }
      end

    end
  end

  def view_email
    @public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
    raise ActiveRecord::RecordNotFound.new("None found") if @public_body.nil?

    AlaveteliLocalization.with_locale(AlaveteliLocalization.locale) do
      if params[:submitted_view_email]
        if verify_recaptcha
          flash.discard(:error)
          render :template => "public_body/view_email"
          return
        end
        flash.now[:error] = _('There was an error with the reCAPTCHA. ' \
                              'Please try again.')
      end
      render :template => "public_body/view_email_captcha"
    end
  end

  def list
    long_cache

    @tag = params[:tag] || 'all'
    @tag = Unicode.upcase(@tag) if @tag.scan(/./mu).size == 1

    @country_code = AlaveteliConfiguration.iso_country_code
    @locale = AlaveteliLocalization.locale

    AlaveteliLocalization.with_locale(@locale) do
      @public_bodies = PublicBody.visible.
                                  with_tag(@tag).
                                  with_query(params[:public_body_query], @tag).
                                  paginate(page: params[:page], per_page: 100)

    @description =
      if @tag == 'all'
        n_('Found {{count}} public authority',
           'Found {{count}} public authorities',
           @public_bodies.total_entries,
           :count => @public_bodies.total_entries)
      elsif @tag.size == 1
        n_('Found {{count}} public authority beginning with ' \
           '‘{{first_letter}}’',
           'Found {{count}} public authorities beginning with ' \
           '‘{{first_letter}}’',
           @public_bodies.total_entries,
           :count => @public_bodies.total_entries,
           :first_letter => @tag)
      else
        category_name = PublicBodyCategory.get.by_tag[@tag]
        if category_name.nil?
          n_('Found {{count}} public authority matching the tag ' \
             '‘{{tag_name}}’',
             'Found {{count}} public authorities matching the tag ' \
             '‘{{tag_name}}’',
             @public_bodies.total_entries,
             :count => @public_bodies.total_entries,
             :tag_name => @tag)
        else
          n_('Found {{count}} public authority in the category ' \
             '‘{{category_name}}’',
             'Found {{count}} public authorities in the category ' \
             '‘{{category_name}}’',
             @public_bodies.total_entries,
             :count => @public_bodies.total_entries,
             :category_name => category_name)
        end
      end

      respond_to do |format|
        format.html { render :template => 'public_body/list' }
      end
    end
  end

  # Used so URLs like /local/islington work, for use e.g. writing to a local paper.
  def list_redirect
    @tag = params[:tag]
    redirect_to list_public_bodies_url(:tag => @tag)
  end

  # GET /body/all-authorities.csv
  #
  # Returns all public bodies (except for the internal admin authority) as CSV
  def list_all_csv
    # FIXME: this is just using the download directory for zip
    # archives, since we know that is allowed for X-Sendfile and
    # the filename can't clash with the numeric subdirectory names
    # used for the zips.  However, really there should be a
    # generically named downloads directory that contains all
    # kinds of downloadable assets.
    download_directory = File.join(InfoRequest.download_zip_dir, 'download')
    FileUtils.mkdir_p(download_directory)
    output_leafname = 'all-authorities.csv'
    output_filename = File.join(download_directory, output_leafname)
    # Create a temporary file in the same directory, so we can
    # rename it atomically to the intended filename:
    tmp = Tempfile.new(output_leafname, download_directory)
    tmp.close

    # Create the CSV
    csv = PublicBodyCSV.new
    PublicBody.includes(:translations, :tags).visible.find_each do |public_body|
      next if public_body.site_administration?
      csv << public_body
    end

    # Export all the public bodies to that temporary path, make it readable,
    # and rename it
    File.open(tmp.path, 'w') { |file| file.write(csv.generate) }
    FileUtils.chmod(0644, tmp.path)
    File.rename(tmp.path, output_filename)

    # Send the file
    send_file(output_filename,
              :type => 'text/csv; charset=utf-8; header=present',
              :filename => 'all-authorities.csv',
              :disposition =>'attachment',
              :encoding => 'utf8')
  end

  # Type ahead search
  def search_typeahead
    query = params[:query]
    flash[:search_params] = params.slice(:query, :bodies, :page)
    @xapian_requests = typeahead_search(query, :model => PublicBody)
    render :partial => "public_body/search_ahead"
  end

end

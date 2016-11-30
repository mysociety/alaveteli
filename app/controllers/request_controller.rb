# -*- encoding : utf-8 -*-
# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'zip/zip'
require 'open-uri'

class RequestController < ApplicationController
  before_filter :check_read_only, :only => [ :new, :describe_state, :upload_response ]
  before_filter :check_batch_requests_and_user_allowed, :only => [ :select_authorities, :new_batch ]
  before_filter :set_render_recaptcha, :only => [ :new ]
  MAX_RESULTS = 500
  PER_PAGE = 25

  @@custom_states_loaded = false
  begin
    require 'customstates'
    include RequestControllerCustomStates
    @@custom_states_loaded = true
  rescue MissingSourceFile, NameError
  end

  def select_authority
    # Check whether we force the user to sign in right at the start, or we allow her
    # to start filling the request anonymously
    if AlaveteliConfiguration::force_registration_on_new_request && !authenticated?(
        :web => _("To send your FOI request"),
        :email => _("Then you'll be allowed to send FOI requests."),
        :email_subject => _("Confirm your email address")
      )
      # do nothing - as "authenticated?" has done the redirect to signin page for us
      return
    end
    if !params[:query].nil?
      query = params[:query]
      flash[:search_params] = params.slice(:query, :bodies, :page)
      @xapian_requests = perform_search_typeahead(query, PublicBody)
    end
    medium_cache
  end

  def select_authorities
    if !params[:public_body_query].nil?
      @search_bodies = perform_search_typeahead(params[:public_body_query], PublicBody, 1000)
    end
    respond_to do |format|
      format.html do
        if !params[:public_body_ids].nil?
          if !params[:remove_public_body_ids].nil?
            body_ids = params[:public_body_ids] - params[:remove_public_body_ids]
          else
            body_ids = params[:public_body_ids]
          end
          @public_bodies = PublicBody.where(:id => body_ids)
        end
      end
      format.json do
        if @search_bodies
          render :json => @search_bodies.results.map{ |result| {:name => result[:model].name,
                                                                :id => result[:model].id } }
        else
          render :json => []
        end
      end
    end
  end

  def show
    if !AlaveteliConfiguration::varnish_host.blank?
      # If varnish is set up to accept PURGEs, then cache for a
      # long time
      long_cache
    else
      medium_cache
    end
    @locale = I18n.locale.to_s
    I18n.with_locale(@locale) do

      # Look up by old style numeric identifiers
      if params[:url_title].match(/^[0-9]+$/)
        @info_request = InfoRequest.find(params[:url_title].to_i)
        redirect_to request_url(@info_request, :format => params[:format])
        return
      end

      # Look up by new style text names
      @info_request = InfoRequest.find_by_url_title!(params[:url_title])

      # Test for whole request being hidden
      if cannot?(:read, @info_request)
        return render_hidden
      end

      set_last_request(@info_request)

      # assign variables from request parameters
      @collapse_quotes = !params[:unfold]
      # Don't allow status update on external requests, otherwise accept param
      if @info_request.is_external?
        @update_status = false
      else
        @update_status = params[:update_status]
      end

      assign_variables_for_show_template(@info_request)

      if @update_status
        return if !@is_owning_user && !authenticated_as_user?(
          @info_request.user,
          :web => _("To update the status of this FOI request"),
          :email => _("Then you can update the status of your request to " \
                        "{{authority_name}}.",
                      :authority_name => @info_request.public_body.name),
          :email_subject => _("Update the status of your request to " \
                                "{{authority_name}}",
                              :authority_name => @info_request.public_body.name)
        )
      end

      # Sidebar stuff
      @sidebar = true
      @similar_cache_key = cache_key_for_similar_requests(@info_request, @locale)

      # Track corresponding to this page
      @track_thing = TrackThing.create_track_for_request(@info_request)
      @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

      respond_to do |format|
        format.html { @has_json = true; render :template => 'request/show'}
        format.json { render :json => @info_request.json_for_api(true) }
      end
    end
  end

  # Extra info about a request, such as event history
  def details
    long_cache
    @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    if cannot?(:read, @info_request)
      return render_hidden
    end
    @columns = ['id', 'event_type', 'created_at', 'described_state', 'last_described_at', 'calculated_state' ]
  end

  # Requests similar to this one
  def similar
    short_cache
    @per_page = 25
    @page = (params[:page] || "1").to_i

    # Later pages are very expensive to load
    if @page > MAX_RESULTS / PER_PAGE
      raise ActiveRecord::RecordNotFound.new("Sorry. No pages after #{MAX_RESULTS / PER_PAGE}.")
    end
    @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    raise ActiveRecord::RecordNotFound.new("Request not found") if @info_request.nil?

    if cannot?(:read, @info_request)
      return render_hidden
    end
    @xapian_object = ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events,
                                               :offset => (@page - 1) * @per_page, :limit => @per_page, :collapse_by_prefix => 'request_collapse')
    @matches_estimated = @xapian_object.matches_estimated
    @show_no_more_than = (@matches_estimated > MAX_RESULTS) ? MAX_RESULTS : @matches_estimated
  end

  def list
    # respond with a 404 without a database lookup if request was not for html
    if request.format && !request.format.html?
      respond_to { |format| format.any { head :not_found } }
      return
    end

    medium_cache
    @view = params[:view]
    @locale = I18n.locale.to_s
    @page = get_search_page_from_params if !@page # used in cache case, as perform_search sets @page as side effect
    @per_page = PER_PAGE
    @max_results = MAX_RESULTS
    if @view == "recent"
      return redirect_to request_list_all_url(:action => "list", :view => "all", :page => @page), :status => :moved_permanently
    end

    # Later pages are very expensive to load
    if @page > MAX_RESULTS / PER_PAGE
      raise ActiveRecord::RecordNotFound.new("Sorry. No pages after #{MAX_RESULTS / PER_PAGE}.")
    end

    @filters = params.merge(:latest_status => @view)

    if (@page > 1)
      @title = _("Browse and search requests (page {{count}})", :count => @page)
    else
      @title = _('Browse and search requests')
    end

    @track_thing = TrackThing.create_track_for_search_query(InfoRequestEvent.make_query_from_params(@filters))
    @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

    # Don't let robots go more than 20 pages in
    if @page > 20
      @no_crawl = true
    end
  end

  def new_batch
    if params[:public_body_ids].blank?
      redirect_to select_authorities_path and return
    end

    # TODO: Decide if we make batch requesters describe their undescribed requests
    # before being able to make a new batch request

    if  !authenticated_user.can_file_requests?
      @details = authenticated_user.can_fail_html
      render :template => 'user/banned' and return
    end

    @batch = true

    I18n.with_locale(@locale) do
      @public_bodies =
        PublicBody.
          where(:id => params[:public_body_ids]).
            includes(:translations).
              order('public_body_translations.name')
    end

    if params[:submitted_new_request].nil? || params[:reedit]
      return render_new_compose(batch=true)
    end

    # Check for double submission of batch
    @existing_batch = InfoRequestBatch.find_existing(authenticated_user,
                                                     params[:info_request][:title],
                                                     params[:outgoing_message][:body],
                                                     params[:public_body_ids])

    @info_request = InfoRequest.create_from_attributes(info_request_params(@batch),
                                                       outgoing_message_params,
                                                       authenticated_user)
    @outgoing_message = @info_request.outgoing_messages.first
    @info_request.is_batch_request_template = true
    if !@existing_batch.nil? || !@info_request.valid?
      # We don't want the error "Outgoing messages is invalid", as in this
      # case the list of errors will also contain a more specific error
      # describing the reason it is invalid.
      @info_request.errors.delete(:outgoing_messages)
      render :action => 'new'
      return
    end

    # Show preview page, if it is a preview
    if params[:preview].to_i == 1
      return render_new_preview
    end

    @info_request_batch = InfoRequestBatch.create!(:title => params[:info_request][:title],
                                                   :body => params[:outgoing_message][:body],
                                                   :public_bodies => @public_bodies,
                                                   :user => authenticated_user)

    flash[:batch_sent] = true
    redirect_to info_request_batch_path(@info_request_batch)
  end

  # Page new form posts to
  def new
    # All new requests are of normal_sort
    if !params[:outgoing_message].nil?
      params[:outgoing_message][:what_doing] = 'normal_sort'
    end

    # If we've just got here (so no writing to lose), and we're already
    # logged in, force the user to describe any undescribed requests. Allow
    # margin of 1 undescribed so it isn't too annoying - the function
    # get_undescribed_requests also allows one day since the response
    # arrived.
    if !@user.nil? && params[:submitted_new_request].nil?
      @undescribed_requests = @user.get_undescribed_requests
      if @undescribed_requests.size > 1
        render :action => 'new_please_describe'
        return
      end
    end

    # Banned from making new requests?
    user_exceeded_limit = false
    if !authenticated_user.nil? && !authenticated_user.can_file_requests?
      # If the reason the user cannot make new requests is that they are
      # rate-limited, it’s possible they composed a request before they
      # logged in and we want to include the text of the request so they
      # can squirrel it away for tomorrow, so we detect this later after
      # we have constructed the InfoRequest.
      user_exceeded_limit = authenticated_user.exceeded_limit?
      if !user_exceeded_limit
        @details = authenticated_user.can_fail_html
        render :template => 'user/banned'
        return
      end
      # User did exceed limit
      @next_request_permitted_at = authenticated_user.next_request_permitted_at
    end

    # First time we get to the page, just display it
    if params[:submitted_new_request].nil? || params[:reedit]
      if user_exceeded_limit
        render :template => 'user/rate_limited'
        return
      end
      return render_new_compose(batch=false)
    end

    # CREATE ACTION

    # Check we have :public_body_id - spammers seem to be using :public_body
    # erroneously instead
    if params[:info_request][:public_body_id].blank?
      redirect_to frontpage_path and return
    end

    # See if the exact same request has already been submitted
    # TODO: this check should theoretically be a validation rule in the
    # model, except we really want to pass @existing_request to the view so
    # it can link to it.
    @existing_request = InfoRequest.find_existing(params[:info_request][:title], params[:info_request][:public_body_id], params[:outgoing_message][:body])

    # Create both FOI request and the first request message
    @info_request = InfoRequest.create_from_attributes(info_request_params,
                                                       outgoing_message_params)
    @outgoing_message = @info_request.outgoing_messages.first

    # Maybe we lost the address while they're writing it
    unless @info_request.public_body.is_requestable?
      render :action => "new_#{ @info_request.public_body.not_requestable_reason }"
      return
    end

    # See if values were valid or not
    if @existing_request || !@info_request.valid?
      # We don't want the error "Outgoing messages is invalid", as in this
      # case the list of errors will also contain a more specific error
      # describing the reason it is invalid.
      @info_request.errors.delete(:outgoing_messages)

      render :action => 'new'
      return
    end

    # Show preview page, if it is a preview
    if params[:preview].to_i == 1
      return render_new_preview
    end

    if user_exceeded_limit
      render :template => 'user/rate_limited'
      return
    end

    if !authenticated?(
        :web => _("To send your FOI request").to_str,
        :email => _("Then your FOI request to {{public_body_name}} will be sent.",:public_body_name=>@info_request.public_body.name),
        :email_subject => _("Confirm your FOI request to {{public_body_name}}",:public_body_name=>@info_request.public_body.name)
      )
      # do nothing - as "authenticated?" has done the redirect to signin page for us
      return
    end

    if params[:post_redirect_user]
      # If an admin has clicked the confirmation link on a users behalf,
      # we don’t want to reassign the request to the administrator.
      @info_request.user = params[:post_redirect_user]
    else
      @info_request.user = authenticated_user
    end

    if AlaveteliConfiguration.enable_anti_spam && !@user.confirmed_not_spam?

      if AlaveteliSpamTermChecker.new.spam?(@outgoing_message.subject)
        flash.now[:error] = "Sorry, we're currently not able to send your request. Please try again later."
        if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
          e = Exception.new("Spam request from user #{@info_request.user.id}")
          ExceptionNotifier.notify_exception(e, :env => request.env)
        end
        render :action => 'new'
        return
      end

      # temp blocking of request sending from other countries
      ip_in_blocklist = AlaveteliConfiguration.restricted_countries.include?(country_from_ip) &&
        country_from_ip != AlaveteliConfiguration.iso_country_code

      if ip_in_blocklist
        flash.now[:error] = "Sorry, we're currently not able to send your request. Please try again later."
        if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
          e = Exception.new("Possible blocked non-spam (ip_in_blocklist) from #{@info_request.user_id}: #{@info_request.title}")
          ExceptionNotifier.notify_exception(e, :env => request.env)
        end
        render :action => 'new'
        return
      end
    end

    if AlaveteliConfiguration.new_request_recaptcha && !@user.confirmed_not_spam?
     if @render_recaptcha && !verify_recaptcha
        flash.now[:error] = "There was an error with the reCAPTCHA information - please try again."
        if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
          e = Exception.new("Possible blocked non-spam (recaptcha) from #{@info_request.user_id}: #{@info_request.title}")
          ExceptionNotifier.notify_exception(e, :env => request.env)
        end
        render :action => 'new'
        return
      end
    end

    # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
    @info_request.save!

    # TODO: Sending the message needs the database id, so we send after
    # saving, which isn't ideal if the request broke here.
    if @outgoing_message.sendable?
      mail_message = OutgoingMailer.initial_request(
        @outgoing_message.info_request,
        @outgoing_message
      ).deliver

      @outgoing_message.record_email_delivery(
        mail_message.to_addrs.join(', '),
        mail_message.message_id
      )
    end

    flash[:request_sent] = true
    redirect_to show_request_path(:url_title => @info_request.url_title)
  end

  # Submitted to the describing state of messages form
  def describe_state
    info_request = InfoRequest.find(params[:id].to_i)
    set_last_request(info_request)

    # If this is an external request, go to the request page - we don't allow
    # state change from the front end interface.
    if info_request.is_external?
      redirect_to request_url(info_request)
      return
    end

    # Check authenticated, and parameters set.
    unless can?(:update_request_state, info_request)
      authenticated_as_user?(
        info_request.user,
        :web => _("To classify the response to this FOI request"),
        :email => _("Then you can classify the FOI response you have got " \
                      "from {{authority_name}}.",
                    :authority_name => info_request.public_body.name),
        :email_subject => _("Classify an FOI response from {{authority_name}}",
                            :authority_name => info_request.public_body.name))
      # do nothing - as "authenticated?" has done the redirect to signin page for us
      return
    end

    if !params[:incoming_message]
      flash[:error] = _("Please choose whether or not you got some of the information that you wanted.")
      redirect_to request_url(info_request)
      return
    end

    if params[:last_info_request_event_id].to_i != info_request.last_event_id_needing_description
      flash[:error] = _("The request has been updated since you originally loaded this page. Please check for any new incoming messages below, and try again.")
      redirect_to request_url(info_request)
      return
    end

    described_state = params[:incoming_message][:described_state]
    message = params[:incoming_message][:message]
    # For requires_admin and error_message states we ask for an extra message to send to
    # the administrators.
    # If this message hasn't been included then ask for it
    if ["error_message", "requires_admin"].include?(described_state) && message.nil?
      redirect_to describe_state_message_url(:url_title => info_request.url_title, :described_state => described_state)
      return
    end

    # Make the state change
    event = info_request.log_event("status_update",
                                   { :user_id => authenticated_user.id,
                                     :old_described_state => info_request.described_state,
                                     :described_state => described_state,
                                     })

    info_request.set_described_state(described_state, authenticated_user, message)

    # If you're not the *actual* requester. e.g. you are playing the
    # classification game, or you're doing this just because you are an
    # admin user (not because you also own the request).
    if !info_request.is_actual_owning_user?(authenticated_user)
      # Create a classification event for league tables
      RequestClassification.create!(:user_id => authenticated_user.id,
                                    :info_request_event_id => event.id)

      # Don't give advice on what to do next, as it isn't their request
      if session[:request_game]
        flash[:notice] = _('Thank you for updating the status of the request \'<a href="{{url}}">{{info_request_title}}</a>\'. There are some more requests below for you to classify.',:info_request_title=>CGI.escapeHTML(info_request.title), :url=>CGI.escapeHTML(request_path(info_request)))
        redirect_to categorise_play_url
      else
        flash[:notice] = _('Thank you for updating this request!')
        redirect_to request_url(info_request)
      end
      return
    end

    # Display advice for requester on what to do next, as appropriate
    calculated_status = info_request.calculate_status
    partial_path = 'request/describe_notices'
    if template_exists?(calculated_status, [partial_path], true)
      flash[:notice] = render_to_string(
          :partial => "#{partial_path}/#{calculated_status}",
          :locals => {:info_request => info_request}
      ).html_safe
    end

    case calculated_status
    when 'waiting_response', 'waiting_response_overdue', 'not_held', 'successful',
        'internal_review', 'error_message', 'requires_admin'
      redirect_to request_url(info_request)
    when 'waiting_response_very_overdue', 'rejected', 'partially_successful'
      redirect_to unhappy_url(info_request)
    when 'waiting_clarification', 'user_withdrawn'
      redirect_to respond_to_last_url(info_request)
    when 'gone_postal'
      redirect_to respond_to_last_url(info_request) + "?gone_postal=1"
    else
      if @@custom_states_loaded
        return self.theme_describe_state(info_request)
      else
        raise "unknown calculate_status #{info_request.calculate_status}"
      end
    end
  end

  # Collect a message to include with the change of state
  def describe_state_message
    @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    @described_state = params[:described_state]
    @last_info_request_event_id = @info_request.last_event_id_needing_description
    @title = case @described_state
    when "error_message"
      _("I've received an error message")
    when "requires_admin"
      _("This request requires administrator attention")
    else
      raise "Unsupported state"
    end
  end

  # Used for links from polymorphic URLs e.g. in Atom feeds - just redirect to
  # proper URL for the message the event refers to
  def show_request_event
    @info_request_event = InfoRequestEvent.find(params[:info_request_event_id])
    if @info_request_event.is_incoming_message?
      redirect_to incoming_message_url(@info_request_event.incoming_message), :status => :moved_permanently
    elsif @info_request_event.is_outgoing_message?
      redirect_to outgoing_message_url(@info_request_event.outgoing_message), :status => :moved_permanently
    else
      # TODO: maybe there are better URLs for some events than this
      redirect_to request_url(@info_request_event.info_request), :status => :moved_permanently
    end
  end

  before_filter :authenticate_attachment, :only => [ :get_attachment, :get_attachment_as_html ]
  def authenticate_attachment
    # Test for hidden
    incoming_message = IncomingMessage.find(params[:incoming_message_id])
    raise ActiveRecord::RecordNotFound.new("Message not found") if incoming_message.nil?
    if cannot?(:read, incoming_message.info_request)
      @info_request = incoming_message.info_request # used by view
      return render_hidden
    end
    if cannot?(:read, incoming_message)
      @incoming_message = incoming_message # used by view
      return render_hidden('request/hidden_correspondence')
    end
    # Is this a completely public request that we can cache attachments for
    # to be served up without authentication?
    if incoming_message.info_request.all_can_view? && incoming_message.all_can_view?
      @files_can_be_cached = true
    end
  end

  # special caching code so mime types are handled right
  around_filter :cache_attachments, :only => [ :get_attachment, :get_attachment_as_html ]
  def cache_attachments
    if !params[:skip_cache].nil?
      yield
    else
      key = params.merge(:only_path => true)
      key_path = foi_fragment_cache_path(key)
      if foi_fragment_cache_exists?(key_path)
        logger.info("Reading cache for #{key_path}")

        if File.directory?(key_path)
          render :text => "Directory listing not allowed", :status => 403
        else
          render :text => foi_fragment_cache_read(key_path),
            :content_type => (AlaveteliFileTypes.filename_to_mimetype(params[:file_name]) || 'application/octet-stream')
        end
        return
      end

      yield

      if params[:skip_cache].nil? && response.status == 200
        # write it to the fileystem ourselves, so is just a plain file. (The
        # various fragment cache functions using Ruby Marshall to write the file
        # which adds a header, so isnt compatible with images that have been
        # extracted elsewhere from PDFs)
        if @files_can_be_cached == true
          logger.info("Writing cache for #{key_path}")
          foi_fragment_cache_write(key_path, response.body)
        end
      end
    end
  end

  def get_attachment
    get_attachment_internal(false)
    return unless @attachment


    # we don't use @attachment.content_type here, as we want same mime type when cached in cache_attachments above
    response.content_type = AlaveteliFileTypes.filename_to_mimetype(params[:file_name]) || 'application/octet-stream'

    # Prevent spam to magic request address. Note that the binary
    # subsitution method used depends on the content type
    body = @incoming_message.
            apply_masks(@attachment.default_body, @attachment.content_type)

    if response.content_type == 'text/html'
      body = ActionController::Base.helpers.sanitize(body)
    end

    render :text => body
  end

  def get_attachment_as_html

    # The conversion process can generate files in the cache directory that can be served up
    # directly by the webserver according to httpd.conf, so don't allow it unless that's OK.
    if @files_can_be_cached != true
      raise ActiveRecord::RecordNotFound.new("Attachment HTML not found.")
    end
    get_attachment_internal(true)
    return unless @attachment

    # images made during conversion (e.g. images in PDF files) are put in the cache directory, so
    # the same cache code in cache_attachments above will display them.
    key = params.merge(:only_path => true)
    key_path = foi_fragment_cache_path(key)
    image_dir = File.dirname(key_path)
    FileUtils.mkdir_p(image_dir)

    html = @attachment.body_as_html(image_dir,
                                    :attachment_url => Rack::Utils.escape(@attachment_url),
                                    :content_for => {
                                      :head_suffix => render_to_string(:partial => "request/view_html_stylesheet"),
                                      :body_prefix => render_to_string(:partial => "request/view_html_prefix")
                                    })

    response.content_type = 'text/html'

    html = @incoming_message.apply_masks(html, response.content_type)

    render :text => html
  end

  # Internal function
  def get_attachment_internal(html_conversion)
    @incoming_message = IncomingMessage.find(params[:incoming_message_id])
    @requested_request = InfoRequest.find(params[:id])
    @incoming_message.parse_raw_email!
    @info_request = @incoming_message.info_request
    if @incoming_message.info_request_id != params[:id].to_i
      # Note that params[:id] might not be an integer, though
      # if we’ve got this far then it must begin with an integer
      # and that integer must be the id number of an actual request.
      message = "Incoming message %d does not belong to request '%s'" % [@incoming_message.info_request_id, params[:id]]
      raise ActiveRecord::RecordNotFound.new(message)
    end
    @part_number = params[:part].to_i
    @filename = params[:file_name]
    if html_conversion
      @original_filename = @filename.gsub(/\.html$/, "")
    else
      @original_filename = @filename
    end

    # check permissions
    raise "internal error, pre-auth filter should have caught this" if cannot?(:read, @info_request)
    @attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(@incoming_message.get_attachments_for_display, @part_number, @original_filename)
    # If we can't find the right attachment, redirect to the incoming message:
    unless @attachment
      return redirect_to incoming_message_url(@incoming_message), :status => 303
    end

    # check filename in URL matches that in database (use a censor rule if you want to change a filename)
    if @attachment.display_filename != @original_filename && @attachment.old_display_filename != @original_filename
      msg = 'please use same filename as original file has, display: '
      msg += "'#{ @attachment.display_filename }' "
      msg += 'old_display: '
      msg += "'#{ @attachment.old_display_filename }' "
      msg += 'original: '
      msg += "'#{ @original_filename }'"
      raise ActiveRecord::RecordNotFound.new(msg)
    end

    @attachment_url = get_attachment_url(:id => @incoming_message.info_request_id,
                                         :incoming_message_id => @incoming_message.id, :part => @part_number,
                                         :file_name => @original_filename )
  end

  # FOI officers can upload a response
  def upload_response
    @locale = I18n.locale.to_s
    I18n.with_locale(@locale) do
      @info_request = InfoRequest.find_by_url_title!(params[:url_title])

      @reason_params = {
        :web => _("To upload a response, you must be logged in using an " \
                    "email address from {{authority_name}}",
                  :authority_name => CGI.escapeHTML(@info_request.public_body.name)),
        :email => _("Then you can upload an FOI response. "),
        :email_subject => _("Confirm your account on {{site_name}}",
                            :site_name => site_name)
      }

      if !authenticated?(@reason_params)
        return
      end

      if !@info_request.public_body.is_foi_officer?(@user)
        domain_required = @info_request.public_body.foi_officer_domain_required
        if domain_required.nil?
          render :template => 'user/wrong_user_unknown_email'
          return
        end
        @reason_params[:user_name] = "an email @" + domain_required
        render :template => 'user/wrong_user'
        return
      end
    end
    if params[:submitted_upload_response]
      file_name = nil
      file_content = nil
      if !params[:file_1].nil?
        file_name = params[:file_1].original_filename
        file_content = params[:file_1].read
      end
      body = params[:body] || ""

      if file_name.nil? && body.empty?
        flash[:error] = _("Please type a message and/or choose a file " \
                            "containing your response.")
        return
      end

      mail = RequestMailer.fake_response(@info_request, @user, body, file_name, file_content)

      @info_request.receive(mail, mail.encoded, true)
      flash[:notice] = _("Thank you for responding to this FOI request! " \
                           "Your response has been published below, and a " \
                           "link to your response has been emailed to {{user_name}}.",
                         :user_name => CGI.escapeHTML(@info_request.user.name))
      redirect_to request_url(@info_request)
      return
    end
  end

  # Type ahead search
  def search_typeahead
    # Since acts_as_xapian doesn't support the Partial match flag, we work
    # around it by making the last word a wildcard, which is quite the same
    @query = ''

    if params.key?(:requested_from)
      @query << "requested_from:#{ params[:requested_from] } "
    end

    @per_page = (params.fetch(:per_page) { 25 }).to_i

    @query << params[:q]
    @xapian_requests = perform_search_typeahead(@query, InfoRequestEvent, @per_page)
    render :partial => "request/search_ahead"
  end

  def download_entire_request
    @locale = I18n.locale.to_s
    I18n.with_locale(@locale) do
      @info_request = InfoRequest.find_by_url_title!(params[:url_title])
      if authenticated?(
          :web => _("To download the zip file"),
          :email => _("Then you can download a zip file of {{info_request_title}}.",
                      :info_request_title=>@info_request.title),
          :email_subject => _("Log in to download a zip file of {{info_request_title}}",
                              :info_request_title=>@info_request.title)
        )
        # Test for whole request being hidden or requester-only
        if cannot?(:read, @info_request)
          return render_hidden
        end
        cache_file_path = @info_request.make_zip_cache_path(@user)
        if !File.exists?(cache_file_path)
          FileUtils.mkdir_p(File.dirname(cache_file_path))
          make_request_zip(@info_request, cache_file_path)
          File.chmod(0644, cache_file_path)
        end
        send_file(cache_file_path, :filename => "#{@info_request.url_title}.zip")
      end
    end
  end

  private

  def info_request_params(batch = false)
    if batch
      unless params[:info_request].nil? || params[:info_request].empty?
        params.require(:info_request).permit(:title, :tag_string)
      end
    else
      params.require(:info_request).permit(:title, :public_body_id, :tag_string)
    end
  end

  def outgoing_message_params
    params.require(:outgoing_message).permit(:body, :what_doing)
  end

  def assign_variables_for_show_template(info_request)
    @info_request = info_request
    @info_request_events = info_request.info_request_events
    @status = info_request.calculate_status
    @old_unclassified = info_request.is_old_unclassified? && !authenticated_user.nil?
    @is_owning_user = info_request.is_owning_user?(authenticated_user)
    @last_info_request_event_id = info_request.last_event_id_needing_description
    @new_responses_count = info_request.events_needing_description.select {|i| i.event_type == 'response'}.size
    # For send followup link at bottom
    @last_response = info_request.get_last_public_response
    @follower_count = @info_request.track_things.count + 1
  end

  def make_request_zip(info_request, file_path)
    Zip::ZipFile.open(file_path, Zip::ZipFile::CREATE) do |zipfile|
      file_info = make_request_summary_file(info_request)
      zipfile.get_output_stream(file_info[:filename]) { |f| f.puts(file_info[:data]) }
      message_index = 0
      info_request.incoming_messages.each do |message|
        next unless can?(:read, message)
        message_index += 1
        message.get_attachments_for_display.each do |attachment|
          filename = "#{message_index}_#{attachment.url_part_number}_#{attachment.display_filename}"
          zipfile.get_output_stream(filename) { |f| f.puts(attachment.body) }
        end
      end
    end
  end

  def make_request_summary_file(info_request)
    done = false
    convert_command = AlaveteliConfiguration::html_to_pdf_command
    assign_variables_for_show_template(info_request)
    if !convert_command.blank? && File.exists?(convert_command)
      @render_to_file = true
      html_output = render_to_string(:template => 'request/show')
      tmp_input = Tempfile.new(['foihtml2pdf-input', '.html'])
      tmp_input.write(html_output)
      tmp_input.close
      tmp_output = Tempfile.new('foihtml2pdf-output')
      output = AlaveteliExternalCommand.run(convert_command, tmp_input.path, tmp_output.path)
      if !output.nil?
        file_info = { :filename => 'correspondence.pdf',
                      :data => File.open(tmp_output.path).read }
        done = true
      else
        logger.error("Could not convert info request #{info_request.id} to PDF with command '#{convert_command} #{tmp_input.path} #{tmp_output.path}'")
      end
      tmp_output.close
      tmp_input.delete
      tmp_output.delete
    else
      logger.warn("No HTML -> PDF converter found at #{convert_command}")
    end
    if !done
      file_info = { :filename => 'correspondence.txt',
                    :data => render_to_string(:template => 'request/show',
                                              :layout => false,
                                              :formats => [:text]) }
    end
    file_info
  end

  def cache_key_for_similar_requests(info_request, locale)
    "request/similar/#{info_request.id}/#{locale}"
  end

  def check_batch_requests_and_user_allowed
    if !AlaveteliConfiguration::allow_batch_requests
      raise RouteNotFound.new("Page not enabled")
    end
    if !authenticated?(
        :web => _("To make a batch request"),
        :email => _("Then you can make a batch request"),
        :email_subject => _("Make a batch request"),
      :user_name => "a user who has been authorised to make batch requests")
      # do nothing - as "authenticated?" has done the redirect to signin page for us
      return
    end
    if !@user.can_make_batch_requests?
      return render_hidden('request/batch_not_allowed')
    end
  end

  def render_new_compose(batch)
    params[:info_request] = { } if !params[:info_request]

    # Reconstruct the params
    unless batch
      # first the public body (by URL name or id)
      params[:info_request][:public_body_id] ||=
        if params[:url_name]
          if params[:url_name].match(/^[0-9]+$/)
            PublicBody.find(params[:url_name]).id
          else
            public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
            raise ActiveRecord::RecordNotFound.new("None found") if public_body.nil? # TODO: proper 404
            public_body.id
          end
        elsif params[:public_body_id]
          params[:public_body_id]
        end

      if !params[:info_request][:public_body_id]
        # compulsory to have a body by here, or go to front page which is start
        # of process
        redirect_to frontpage_url
        return
      end
    end

    # ... next any tags or other things
    params[:info_request][:title] = params[:title] if params[:title]
    params[:info_request][:tag_string] = params[:tags] if params[:tags]

    @info_request = InfoRequest.new(info_request_params(batch))

    if batch
      @info_request.is_batch_request_template = true
    end
    params[:info_request_id] = @info_request.id

    # Manually permit params because strong params was too difficult given the
    # non-standard arrangement.
    message_params =
      if params[:outgoing_message]
        { :outgoing_message => params[:outgoing_message] }
      else
        { :outgoing_message => {} }
      end

    message_params[:outgoing_message][:body] ||= params[:body] if params[:body]
    message_params[:outgoing_message][:default_letter] ||= params[:default_letter] if params[:default_letter]

    message_params = ActionController::Parameters.new(message_params)
    permitted = message_params.
      permit(:outgoing_message => [:body, :default_letter, :what_doing])

    @outgoing_message = OutgoingMessage.new(:info_request => @info_request)

    if permitted[:outgoing_message][:body]
      @outgoing_message.body = permitted[:outgoing_message][:body]
    end
    if permitted[:outgoing_message][:default_letter]
      @outgoing_message.default_letter = permitted[:outgoing_message][:default_letter]
    end
    if permitted[:outgoing_message][:what_doing]
      @outgoing_message.what_doing = permitted[:outgoing_message][:what_doing]
    end
    @outgoing_message.set_signature_name(@user.name) if !@user.nil?

    if batch
      render :action => 'new'
    else
      if @info_request.public_body.is_requestable?
        render :action => 'new'
      else
        if @info_request.public_body.not_requestable_reason == 'bad_contact'
          render :action => 'new_bad_contact'
        else
          # if not requestable because defunct or not_apply, redirect to main page
          # (which doesn't link to the /new/ URL)
          redirect_to public_body_url(@info_request.public_body)
        end
      end
    end
    return

  end

  def render_new_preview
    message = ""
    if @outgoing_message.contains_email?
      if @user.nil?
        message += _("<p>You do not need to include your email in the " \
                     "request in order to get a reply, as we will ask " \
                     "for it on the next screen (<a href=\"{{url}}\">" \
                     "details</a>).</p>",
                     :url => (help_privacy_path(:anchor => "email_address")).html_safe)
      else
        message += _("<p>You do not need to include your email in the " \
                     "request in order to get a reply (<a href=\"{{url}}\">" \
                     "details</a>).</p>",
                     :url => (help_privacy_path(:anchor => "email_address")).html_safe)
      end
      message += _("<p>We recommend that you edit your request and remove " \
                   "the email address. If you leave it, the email address " \
                   "will be sent to the authority, but will not be " \
                   "displayed on the site.</p>")
    end
    if @outgoing_message.contains_postcode?
      message += _("<p>Your request contains a <strong>postcode</strong>. " \
                   "Unless it directly relates to the subject of your " \
                   "request, please remove any address as it will <strong>" \
                   "appear publicly on the Internet</strong>.</p>")
    end
    if not message.empty?
      flash.now[:error] = message.html_safe
    end
    render :action => 'preview'
  end

  def set_render_recaptcha
    @render_recaptcha = AlaveteliConfiguration.new_request_recaptcha &&
      (!@user || !@user.confirmed_not_spam?)
  end
end

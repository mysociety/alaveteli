# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'zip'

class RequestController < ApplicationController
  skip_before_action :html_response, only: [:show, :select_authorities]

  before_action :check_read_only, only: [:new, :upload_response]
  before_action :set_render_recaptcha, only: [ :new ]
  before_action :set_info_request, only: [:show]
  before_action :redirect_new_form_to_pro_version, only: [:select_authority, :new]
  before_action :set_in_pro_area, only: [:select_authority, :show]
  before_action :setup_results_pagination, only: [:list, :similar]
  before_action :set_no_crawl_headers, only: [:new, :details, :similar]

  helper_method :state_transitions_empty?

  include ProminenceHeaders

  MAX_RESULTS = 500
  PER_PAGE = 25

  def select_authority
    # Check whether we force the user to sign in right at the start, or we allow her
    # to start filling the request anonymously
    if AlaveteliConfiguration.force_registration_on_new_request &&
       !authenticated?
      ask_to_login(
        web: _('To send and publish your FOI request'),
        email: _("Then you'll be allowed to send FOI requests."),
        email_subject: _('Confirm your email address')
      )
      return
    end
    unless params[:query].nil?
      query = params[:query]
      flash[:search_params] = params.slice(:query, :bodies, :page)
      @xapian_requests = typeahead_search(query, model: PublicBody)
    end
    medium_cache
  end

  def show
    medium_cache
    AlaveteliLocalization.with_locale(locale) do
      # Test for whole request being hidden
      return render_hidden if cannot?(:read, @info_request)

      # Always show the pro livery if a request is embargoed. This makes it
      # clear to admins and ex-pro users that the `InfoRequest` is still
      # private.
      @in_pro_area = true if @info_request.embargo

      set_last_request(@info_request)

      # assign variables from request parameters
      @collapse_quotes = !params[:unfold]

      @update_status = can_update_status(@info_request)

      assign_variables_for_show_template(@info_request)

      # Only owners (and people who own everything) can update status
      if @update_status && !@is_owning_user && !authenticated?(
        as: @info_request.user
      )
        ask_to_login(
          as: @info_request.user,
          web: _('To update the status of this FOI request'),
          email: _('Then you can update the status of your request to ' \
                   '{{authority_name}}.',
                   authority_name: @info_request.public_body.name),
          email_subject: _('Update the status of your request to ' \
                           '{{authority_name}}',
                           authority_name: @info_request.public_body.name)
        )
        return
      end

      # What state transitions can the request go into
      assign_state_transition_variables

      # Sidebar stuff
      @sidebar = true
      @sidebar_template = @in_pro_area ? "alaveteli_pro/info_requests/sidebar" : "sidebar"

      # Track corresponding to this page
      @track_thing = TrackThing.create_track_for_request(@info_request)
      @feed_autodetect = [ { url: do_track_url(@track_thing, 'feed'), title: @track_thing.params[:title_in_rss], has_json: true } ]

      respond_to do |format|
        format.html do
          @has_json = true
          render template: 'request/show'
        end
        format.json { render json: @info_request.json_for_api(true) }
      end
    end
  end

  # Extra info about a request, such as event history
  def details
    long_cache
    @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    return render_hidden if cannot?(:read, @info_request)
  end

  # Requests similar to this one
  def similar
    short_cache

    @info_request = InfoRequest.find_by_url_title!(params[:url_title])

    return render_hidden if cannot?(:read, @info_request)

    @xapian_object = ActsAsXapian::Similar.new([InfoRequestEvent],
                                               @info_request.info_request_events,
                                               offset: (@page - 1) * @per_page,
                                               limit: @per_page,
                                               collapse_by_prefix: 'request_collapse')
    @matches_estimated = @xapian_object.matches_estimated
    @show_no_more_than = (@matches_estimated > MAX_RESULTS) ? MAX_RESULTS : @matches_estimated
  end

  def list
    medium_cache

    @filters = params.slice(:query, :request_date_after, :request_date_before)
    @filters[:latest_status] = params[:view]
    @tag = @filters[:tag] = params[:tag]

    @results = InfoRequest.request_list(
      @filters, @page, @per_page, @max_results
    )

    if @tag
      @category = InfoRequest.category_list.find_by(category_tag: @tag)
      @title = @category&.title
      @title ||= n_('Found {{count}} request tagged ‘{{tag_name}}’',
                    'Found {{count}} requests tagged ‘{{tag_name}}’',
                    @results[:matches_estimated],
                    count: @results[:matches_estimated],
                    tag_name: @tag)
    elsif @page > 1
      @title = _("Browse and search requests (page {{count}})", count: @page)
    else
      @title = _('Browse and search requests')
    end

    @track_thing = TrackThing.create_track_for_search_query(InfoRequestEvent.make_query_from_params(@filters))
    @feed_autodetect = [ { url: do_track_url(@track_thing, 'feed'), title: @track_thing.params[:title_in_rss], has_json: true } ]
  end

  # Page new form posts to
  def new
    # All new requests are of normal_sort
    unless params[:outgoing_message].nil?
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
        render action: 'new_please_describe'
        return
      end
    end

    # Banned from making new requests?
    user_exceeded_limit = false
    if authenticated? && !authenticated_user.can_file_requests?
      # If the reason the user cannot make new requests is that they are
      # rate-limited, it’s possible they composed a request before they
      # logged in and we want to include the text of the request so they
      # can squirrel it away for tomorrow, so we detect this later after
      # we have constructed the InfoRequest.
      user_exceeded_limit = authenticated_user.exceeded_limit?(:info_requests)
      unless user_exceeded_limit
        @details = authenticated_user.can_fail_html
        render template: 'user/banned'
        return
      end
      # User did exceed limit
      @next_request_permitted_at = authenticated_user.next_request_permitted_at
    end

    # First time we get to the page, just display it
    if params[:submitted_new_request].nil? || params[:reedit]
      if user_exceeded_limit
        render template: 'user/rate_limited'
        return
      end
      return render_new_compose
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
    @info_request = InfoRequest.build_from_attributes(info_request_params,
                                                      outgoing_message_params)
    @outgoing_message = @info_request.outgoing_messages.first

    # Maybe we lost the address while they're writing it
    unless @info_request.public_body.is_requestable?
      render action: "new_#{ @info_request.public_body.not_requestable_reason }"
      return
    end

    # See if values were valid or not
    if @existing_request || !@info_request.valid?
      # We don't want the error "Outgoing messages is invalid", as in this
      # case the list of errors will also contain a more specific error
      # describing the reason it is invalid.
      @info_request.errors.delete(:outgoing_messages)

      render action: 'new'
      return
    end

    # Show preview page, if it is a preview
    return render_new_preview if params[:preview].to_i == 1

    if user_exceeded_limit
      render template: 'user/rate_limited'
      return
    end

    unless authenticated?
      ask_to_login(
        web: _('To send and publish your FOI request').to_str,
        email: _('Then your FOI request to {{public_body_name}} will be sent ' \
                 'and published.',
                 public_body_name: @info_request.public_body.name),
        email_subject: _('Confirm your FOI request to {{public_body_name}}',
                         public_body_name: @info_request.public_body.name)
      )
      return
    end

    @info_request.user = request_user

    if spam_subject?(@outgoing_message.subject, @user)
      handle_spam_subject(@info_request.user) && return
    end

    if blocked_ip?(country_from_ip, @user)
      handle_blocked_ip(@info_request) && return
    end

    if AlaveteliConfiguration.new_request_recaptcha && !@user.confirmed_not_spam?
      if @render_recaptcha && !verify_recaptcha
        flash.now[:error] = _('There was an error with the reCAPTCHA. ' \
                              'Please try again.')

        if send_exception_notifications?
          e = Exception.new("Possible blocked non-spam (recaptcha) from #{@info_request.user_id}: #{@info_request.title}")
          ExceptionNotifier.notify_exception(e, env: request.env)
        end

        render action: 'new'
        return
      end
    end

    # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
    @info_request.save!

    if @outgoing_message.sendable?
      begin
        mail_message = OutgoingMailer.initial_request(
          @outgoing_message.info_request,
          @outgoing_message
        ).deliver_now

      rescue *OutgoingMessage.expected_send_errors => e
        # Catch a wide variety of potential ActionMailer failures and
        # record the exception reason so administrators don't have to
        # dig into logs.
        @outgoing_message.record_email_failure(
          e.message
        )

        flash[:error] = _("An error occurred while sending your request to " \
                          "{{authority_name}} but has been saved and flagged " \
                          "for administrator attention.",
                          authority_name: @info_request.public_body.name)
      else
        @outgoing_message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id
        )

        flash[:request_sent] = true
      ensure
        # Ensure the InfoRequest is fully updated before templating to
        # isolate templating issues recording delivery status.
        @info_request.save!
      end
    end

    redirect_to show_request_path(@info_request.url_title)
  end

  # Used for links from polymorphic URLs e.g. in Atom feeds - just redirect to
  # proper URL for the message the event refers to
  def show_request_event
    @info_request_event = InfoRequestEvent.find(params[:info_request_event_id])
    if @info_request_event.info_request.embargo
      raise ActiveRecord::RecordNotFound
    end

    if @info_request_event.is_incoming_message?
      redirect_to incoming_message_url(@info_request_event.incoming_message), status: :moved_permanently
    elsif @info_request_event.is_outgoing_message?
      redirect_to outgoing_message_url(@info_request_event.outgoing_message), status: :moved_permanently
    else
      # TODO: maybe there are better URLs for some events than this
      redirect_to request_url(@info_request_event.info_request), status: :moved_permanently
    end
  end

  # FOI officers can upload a response
  def upload_response
    AlaveteliLocalization.with_locale(locale) do
      @info_request = InfoRequest.not_embargoed.find_by_url_title!(params[:url_title])

      @reason_params = {
        web: _('To upload a response, you must be logged in using an ' \
               'email address from {{authority_name}}',
               authority_name: CGI.escapeHTML(@info_request.public_body.name)),
        email: _('Then you can upload an FOI response. '),
        email_subject: _('Confirm your account on {{site_name}}',
                         site_name: site_name)
      }

      unless authenticated?
        ask_to_login(**@reason_params)
        return false
      end

      if @info_request.allow_new_responses_from == 'nobody'
        render template:
          'request/request_subtitle/allow_new_responses_from/_nobody'
        return
      end

      unless @info_request.public_body.is_foi_officer?(@user)
        domain_required = @info_request.public_body.foi_officer_domain_required
        if domain_required.nil?
          render template: 'user/wrong_user_unknown_email'
          return
        end
        @reason_params[:user_name] = "an email @" + domain_required
        render template: 'user/wrong_user'
        return
      end
    end
    if params[:submitted_upload_response]
      file_name = nil
      file_content = nil
      unless params[:file_1].nil?
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

      @info_request.
        receive(mail,
                mail.encoded,
                override_stop_new_responses: true)
      flash[:notice] = _("Thank you for responding to this FOI request! " \
                           "Your response has been published below, and a " \
                           "link to your response has been emailed to {{user_name}}.",
                         user_name: @info_request.user.name.html_safe)
      redirect_to request_url(@info_request)
      nil
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

    @query << params[:q].to_s
    @xapian_requests = typeahead_search(@query,
                                        { model: InfoRequestEvent,
                                          per_page: @per_page })
    render partial: "request/search_ahead"
  end

  def download_entire_request
    AlaveteliLocalization.with_locale(locale) do
      @info_request = InfoRequest.find_by_url_title!(params[:url_title])
      # Check for access and hide emargoed requests immediately, so that we
      # don't leak any info to people who can't access them
      render_hidden if @info_request.embargo && cannot?(:read, @info_request)
      if !authenticated?
        ask_to_login(
          web: _('To download the zip file'),
          email: _('Then you can download a zip file of ' \
                   '{{info_request_title}}.',
                   info_request_title: @info_request.title),
          email_subject: _('Log in to download a zip file of ' \
                           '{{info_request_title}}',
                           info_request_title: @info_request.title)
        )
      else
        # Test for whole request being hidden or requester-only
        return render_hidden if cannot?(:read, @info_request)

        cache_file_path = @info_request.make_zip_cache_path(@user)
        unless File.exist?(cache_file_path)
          FileUtils.mkdir_p(File.dirname(cache_file_path))
          make_request_zip(@info_request, cache_file_path)
          File.chmod(0644, cache_file_path)
        end
        send_file(cache_file_path, filename: "#{@info_request.url_title}.zip")
      end
    end
  end

  private

  def info_request_params
    params.require(:info_request).permit(:title, :public_body_id, :tag_string)
  end

  def outgoing_message_params
    params.require(:outgoing_message).permit(:body, :what_doing)
  end

  def setup_results_pagination
    @page ||= get_search_page_from_params
    @per_page = PER_PAGE
    @max_results = MAX_RESULTS

    # Later pages are very expensive to load
    return if @page <= MAX_RESULTS / PER_PAGE

    raise ActiveRecord::RecordNotFound,
      "Sorry. No pages after #{MAX_RESULTS / PER_PAGE}."
  end

  def can_update_status(info_request)
    # Don't allow status update on external requests, otherwise accept param
    info_request.is_external? ? false : params[:update_status] == "1"
  end

  def assign_variables_for_show_template(info_request)
    @info_request = info_request
    @status = info_request.calculate_status
    @old_unclassified =
      info_request.is_old_unclassified? && authenticated?
    @is_owning_user = info_request.is_owning_user?(authenticated_user)
    @last_info_request_event_id = info_request.last_event_id_needing_description
    @new_responses_count =
      info_request.
      events_needing_description.
      select { |event| event.event_type == 'response' }.
      size
    @follower_count = @info_request.track_things.count + 1

    # For send followup link at bottom
    @last_response = info_request.get_last_public_response

    @show_profile_photo = !!(
      !@info_request.is_external? &&
      @info_request.user.show_profile_photo? &&
      !@render_to_file
    )

    @show_top_describe_state_form = !!(
      !@in_pro_area &&
      (@update_status || @info_request.awaiting_description) &&
      !@render_to_file
    )

    @show_bottom_describe_state_form = !!(
      !@in_pro_area &&
      @info_request.awaiting_description &&
      !@render_to_file
    )

    @show_owner_update_status_action = !!(
      !@old_unclassified && !@render_to_file
    )

    @show_other_user_update_status_action = !!(
      @old_unclassified && !@render_to_file
    )

    @show_action_menu = !@render_to_file

    @similar_requests, @similar_more = @info_request.similar_requests

    @citations = @info_request.citations.newest(3)
  end

  def assign_state_transition_variables
    @state_transitions = @info_request.state.transitions(
      is_pro_user: @in_pro_area,
      is_owning_user: @is_owning_user,
      user_asked_to_update_status: @update_status || @in_pro_area)

    # If there are no available transitions, we shouldn't show any options
    # to update the status
    if state_transitions_empty?(@state_transitions)
      @show_top_describe_state_form = false
      @show_bottom_describe_state_form = false
      @show_owner_update_status_action = false
      @show_other_user_update_status_action = false
    end
  end

  def state_transitions_empty?(transitions)
    return true if transitions.nil?

    transitions[:pending].empty? && \
      transitions[:complete].empty? && \
      transitions[:other].empty?
  end

  def make_request_zip(info_request, file_path)
    Zip::File.open(file_path, create: true) do |zipfile|
      file_info = make_request_summary_file(info_request)
      zipfile.get_output_stream(file_info[:filename]) { |f| f.write(file_info[:data]) }
      message_index = 0
      info_request.incoming_messages.each do |message|
        next unless can?(:read, message)

        message_index += 1
        message.get_attachments_for_display.each do |attachment|
          next unless can?(:read, attachment)

          filename = "#{message_index}_#{attachment.url_part_number}_#{attachment.display_filename}"
          zipfile.get_output_stream(filename) do |f|
            body = message.apply_masks(attachment.default_body, attachment.content_type)
            f.write(body)
          end
        end
      end
    end
  end

  def make_request_summary_file(info_request)
    done = false
    @render_to_file = true
    assign_variables_for_show_template(info_request)
    if HTMLtoPDFConverter.exist?
      html_output = render_to_string(template: 'request/show')
      tmp_input = Tempfile.new(['foihtml2pdf-input', '.html'])
      tmp_input.write(html_output)
      tmp_input.close
      tmp_output = Tempfile.new('foihtml2pdf-output')
      command = HTMLtoPDFConverter.new(tmp_input, tmp_output)
      output = command.run
      if !output.nil?
        file_info = { filename: 'correspondence.pdf',
                      data: File.open(tmp_output.path).read }
        done = true
      else
        logger.error("Could not convert info request #{info_request.id} to PDF with command '#{command}'")
      end
      tmp_output.close
      tmp_input.delete
      tmp_output.delete
    else
      logger.warn("No HTML -> PDF converter found")
    end
    unless done
      file_info = { filename: 'correspondence.txt',
                    data: render_to_string(template: 'request/show',
                                              layout: false,
                                              formats: [:text]) }
    end
    file_info
  end

  def render_new_compose
    params[:info_request] = {} unless params[:info_request]

    # Reconstruct the params
    # first the public body (by URL name or id)
    params[:info_request][:public_body_id] ||=
      if params[:url_name]
        if params[:url_name].match(/^[0-9]+$/)
          PublicBody.find(params[:url_name]).id
        else
          public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
          if public_body.nil?  # TODO: proper 404
            raise ActiveRecord::RecordNotFound, "None found"
          end

          public_body.id
        end
      elsif params[:public_body_id]
        params[:public_body_id]
      end

    unless params[:info_request][:public_body_id]
      # compulsory to have a body by here, or go to front page which is start
      # of process
      redirect_to frontpage_url
      return
    end

    # ... next any tags or other things
    params[:info_request][:title] = params[:title] if params[:title]
    params[:info_request][:tag_string] = params[:tags] if params[:tags]

    @info_request = InfoRequest.new(info_request_params)

    params[:info_request_id] = @info_request.id

    # Manually permit params because strong params was too difficult given the
    # non-standard arrangement.
    message_params =
      if params[:outgoing_message]
        { outgoing_message: params[:outgoing_message] }
      else
        { outgoing_message: {} }
      end

    message_params[:outgoing_message][:body] ||= params[:body] if params[:body]
    if params[:default_letter]
      message_params[:outgoing_message][:default_letter] ||= params[:default_letter]
    end

    message_params = ActionController::Parameters.new(message_params)
    permitted = message_params.
      permit(outgoing_message: [:body, :default_letter, :what_doing])

    @outgoing_message = OutgoingMessage.new(info_request: @info_request)

    if permitted[:outgoing_message][:body]
      @outgoing_message.body = permitted[:outgoing_message][:body]
    end
    if permitted[:outgoing_message][:default_letter]
      @outgoing_message.default_letter = permitted[:outgoing_message][:default_letter]
    end
    if permitted[:outgoing_message][:what_doing]
      @outgoing_message.what_doing = permitted[:outgoing_message][:what_doing]
    end
    @outgoing_message.set_signature_name(@user.name) unless @user.nil?

    if @info_request.public_body.is_requestable?
      render action: 'new'
    elsif @info_request.public_body.not_requestable_reason == 'bad_contact'
      render action: 'new_bad_contact'
    else
      # if not requestable because defunct or not_apply, redirect to main page
      # (which doesn't link to the /new/ URL)
      redirect_to public_body_url(@info_request.public_body)
    end
    nil
  end

  def render_new_preview
    if @outgoing_message.contains_email? || @outgoing_message.contains_postcode?
      flash.now[:error] = {
        partial: "preview_errors",
        locals: {
          contains_email: @outgoing_message.contains_email?,
          contains_postcode: @outgoing_message.contains_postcode?,
          help_link: help_privacy_path(anchor: "email_address"),
          user: @user
        }
      }
    end
    render action: 'preview'
  end

  def set_render_recaptcha
    @render_recaptcha = AlaveteliConfiguration.new_request_recaptcha &&
                        (!@user || !@user.confirmed_not_spam?)
  end

  def redirect_new_form_to_pro_version
    # Pros should use the pro version of the form
    if feature_enabled?(:alaveteli_pro) &&
       request_user &&
       request_user.is_pro? &&
       params[:pro] != "1"
      if params[:url_name]
        redirect_to(
          new_alaveteli_pro_info_request_url(public_body: params[:url_name]))
      else
        redirect_to new_alaveteli_pro_info_request_url
      end
    end
  end

  # If an admin has clicked the confirmation link on a users behalf,
  # we don’t want to reassign the request to the administrator.
  def request_user
    if params[:post_redirect_user]
      params[:post_redirect_user]
    else
      current_user
    end
  end

  def spam_subject?(message_subject, user)
    !user.confirmed_not_spam? &&
      AlaveteliSpamTermChecker.new.spam?(message_subject.to_ascii)
  end

  def block_spam_subject?
    AlaveteliConfiguration.block_spam_requests ||
      AlaveteliConfiguration.enable_anti_spam
  end

  # Sends an exception and blocks the comment depending on configuration.
  def handle_spam_subject(user)
    if send_exception_notifications?
      e = Exception.new("Spam request from user #{ user.id }")
      ExceptionNotifier.notify_exception(e, env: request.env)
    end

    if block_spam_subject?
      flash.now[:error] = _("Sorry, we're currently unable to send your " \
                            "request. Please try again later.")
      render action: 'new'
      true
    end
  end

  def blocked_ip?(ip, user)
    !user.confirmed_not_spam? &&
      AlaveteliConfiguration.restricted_countries.include?(ip) &&
      country_from_ip != AlaveteliConfiguration.iso_country_code
  end

  def block_restricted_country_ips?
    AlaveteliConfiguration.block_restricted_country_ips ||
      AlaveteliConfiguration.enable_anti_spam
  end

  def handle_blocked_ip(info_request)
    if send_exception_notifications?
      msg = "Possible spam request (ip_in_blocklist) from " \
            "User##{info_request.user_id}: #{user_ip} (#{country_from_ip})"
      ExceptionNotifier.notify_exception(Exception.new(msg), env: request.env)
    end

    if block_restricted_country_ips?
      flash.now[:error] = _("Sorry, we're currently unable to send your " \
                            "request. Please try again later.")
      render action: 'new'
      true
    end
  end

  def set_info_request
    AlaveteliLocalization.with_locale(locale) do
      @info_request ||= InfoRequest.find_by_url_title!(params[:url_title])
    end
  end

  def locale
    @locale ||= AlaveteliLocalization.locale
  end

  def with_prominence
    @info_request
  end
end

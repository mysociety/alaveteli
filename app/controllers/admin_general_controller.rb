# app/controllers/admin_controller.rb:
# Controller for main admin pages.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminGeneralController < AdminController
  include AdminGeneralTimelineHelper

  def index
    # Tasks to do
    @requires_admin_requests = InfoRequest.
      find_in_state('requires_admin').
        not_embargoed
    @error_message_requests = InfoRequest.
      find_in_state('error_message').
        not_embargoed
    @attention_requests = InfoRequest.
      find_in_state('attention_requested').
        not_embargoed

    @old_unclassified_count =
      InfoRequest.where_old_unclassified.is_searchable.count

    @old_unclassified = InfoRequest.where_old_unclassified.
                                      limit(20).
                                        is_searchable
    @holding_pen_messages = InfoRequest.
      includes(incoming_messages: :raw_email).
        holding_pen_request.
          incoming_messages
    @public_request_tasks = [ @holding_pen_messages,
                              @error_message_requests,
                              @attention_requests,
                              @requires_admin_requests,
                              @old_unclassified ].
      any? { |to_do_list| ! to_do_list.empty? }

    @blank_contact_count = PublicBody.without_request_email.count
    @blank_contacts = PublicBody.without_request_email.limit(20)

    @new_body_requests = PublicBodyChangeRequest.
      includes(:public_body, :user).
        new_body_requests.
          open
    @body_update_requests = PublicBodyChangeRequest.
      includes(:public_body, :user).
        body_update_requests.
          open

    @authority_tasks = [ @blank_contacts,
                         @new_body_requests,
                         @body_update_requests ].
      any? { |to_do_list| ! to_do_list.empty? }

    # HACK: Running this query through ActiveRecord freezes…
    @attention_comments = Comment.
      find_by_sql(Comment.where(attention_requested: true).not_embargoed.to_sql)

    @comment_tasks = [ @attention_comments ].
      any? { |to_do_list| ! to_do_list.empty? }

    @nothing_to_do = !@public_request_tasks &&
                     !@authority_tasks &&
                     !@comment_tasks

    @announcements = Announcement.
      for_user_with_roles(current_user, :admin, :pro_admin).
      limit(3)

    if can? :admin, AlaveteliPro::Embargo
      @embargoed_requires_admin_requests = InfoRequest.
                                             find_in_state('requires_admin').
                                               embargoed
      @embargoed_error_message_requests = InfoRequest.
                                            find_in_state('error_message').
                                              embargoed
      @embargoed_attention_requests = InfoRequest.
                                        find_in_state('attention_requested').
                                          embargoed

      @embargoed_request_tasks = [
        @embargoed_requires_admin_requests,
        @embargoed_error_message_requests,
        @embargoed_attention_requests
      ].any? { |to_do_list| ! to_do_list.empty? }

      @embargoed_attention_comments = Comment.
                                        where(attention_requested: true).
                                          embargoed

      @embargoed_comment_tasks = [
                                   @embargoed_attention_comments
                                 ].any? { |to_do_list| ! to_do_list.empty? }
      @nothing_to_do = @nothing_to_do &&
                       !@embargoed_request_tasks &&
                       !@embargoed_comment_tasks
    end
  end

  def timeline
    # Recent events
    @events_title = get_events_title

    @events = WillPaginate::Collection.create((params[:page] or 1), 100) do |pager|
      # get the relevant slice from the paginator
      events, count = get_timeline_events(pager)

      # inject the result array into the paginated collection:
      pager.replace(events)

      # set the total entries for the page to the overall number of results
      pager.total_entries = count
    end
  end

  def stats
    # Overview counts of things
    @public_body_count = PublicBody.count

    @info_request_count = InfoRequest.count
    @outgoing_message_count = OutgoingMessage.count
    @incoming_message_count = IncomingMessage.count

    @user_count = User.count
    @track_thing_count = TrackThing.count

    @comment_count = Comment.count
    @request_by_state = InfoRequest.group('described_state').count
    @tracks_by_type = TrackThing.group('track_type').count
  end

  def debug
    @admin_current_user = admin_current_user
    @current_commit = Statistics::General.new.to_h[:alaveteli_git_commit]
    @current_branch = `git branch | perl -ne 'print $1 if /^\\* (.*)/'`
    @current_version = ALAVETELI_VERSION
    repo = `git remote show origin -n | perl -ne 'print $1 if m{Fetch URL: .*github\\.com[:/](.*)\\.git}'`
    @github_origin = "https://github.com/#{repo}/tree/"
    @request_env = request.env
  end

  private

  def get_events_title
    if current_time_filter == 'All time'
      "#{current_event_type}, all time"
    else
      "#{current_event_type} in the last #{current_time_filter.downcase}"
    end
  end

  def get_timeline_events(pager)
    # Get an array of events, timestamps and total record count within the
    # timespan in the selected event type
    #
    # Note that the relevant date for InfoRequestEvents is creation, but
    # for PublicBodyVersions is update throughout
    authority_change_scope = PublicBody.versioned_class.
      select("id, 'PublicBody::Version' as type, updated_at AS timestamp").
      where(updated_at: start_date...).
      order(timestamp: :desc).
      limit(pager.per_page).
      offset(pager.offset)
    authority_change_count = authority_change_scope.
      unscope(:select, :order, :limit, :offset).
      count

    info_request_event_scope = InfoRequestEvent.
      select("id, 'InfoRequestEvent' as type, created_at AS timestamp").
      where(created_at: start_date...).
      order(timestamp: :desc).
      limit(pager.per_page).
      offset(pager.offset)
    info_request_event_count = info_request_event_scope.
      unscope(:select, :order, :limit, :offset).
      count

    case params[:event_type]
    when 'authority_change'
      count = authority_change_count
      scope = authority_change_scope
    when 'info_request_event'
      count = info_request_event_count
      scope = info_request_event_scope
    else
      count = authority_change_count + info_request_event_count
      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL.squish, limit: pager.per_page, offset: pager.offset]
          (#{authority_change_scope.unscope(:order, :limit, :offset).to_sql})
          UNION ALL
          (#{info_request_event_scope.unscope(:order, :limit, :offset).to_sql})
          ORDER BY timestamp DESC
          LIMIT :limit OFFSET :offset
        SQL
      )
      scope = ActiveRecord::Base.connection.select_all(query)
    end

    records_and_timestamps = scope.map do |record|
      [record['type'].constantize.find(record['id']), record['timestamp']]
    end

    [records_and_timestamps, count]
  end
end

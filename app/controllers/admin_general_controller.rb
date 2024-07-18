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
      # create a hash for each model type being returned
      info_request_event_ids = {}
      public_body_version_ids = {}
      # get the relevant slice from the paginator
      timestamps = get_timestamps
      timestamps.slice(pager.offset, pager.per_page).each_with_index do |event, index|
        # for each event in the slice, add an item to the hash for the model type
        # whose key is the model id, and value is the position in the slice
        if event[1] == 'InfoRequestEvent'
          info_request_event_ids[event[0].to_i] = index
        else
          public_body_version_ids[event[0].to_i] = index
        end
      end
      # get all the models in the slice, eagerly loading the associations we use in the view
      public_body_versions = PublicBody.versioned_class.
        includes(public_body: :translations).
          find(public_body_version_ids.keys)
      info_request_events = InfoRequestEvent.
        includes(:info_request).
          find(info_request_event_ids.keys)
      @events = []
      # drop the models into a combined array, ordered by their position in the timestamp slice
      public_body_versions.each do |version|
        @events[public_body_version_ids[version.id]] = [version, version.updated_at]
      end
      info_request_events.each do |event|
        @events[info_request_event_ids[event.id]] = [event, event.created_at]
      end

      # inject the result array into the paginated collection:
      pager.replace(@events)

      # set the total entries for the page to the overall number of results
      pager.total_entries = timestamps.size
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

  private

  def get_events_title
    if current_time_filter == 'All time'
      "#{current_event_type}, all time"
    else
      "#{current_event_type} in the last #{current_time_filter.downcase}"
    end
  end

  def get_timestamps
    # Get an array of event attributes within the timespan in the format
    # [id, type_of_model, event_timestamp]
    # Note that the relevant date for InfoRequestEvents is creation, but
    # for PublicBodyVersions is update throughout
    connection = InfoRequestEvent.connection

    authority_change_scope = PublicBody.versioned_class.
      select("id, 'PublicBodyVersion', updated_at AS timestamp").
      where(updated_at: start_date...).
      order(timestamp: :desc)

    info_request_event_scope = InfoRequestEvent.
      select("id, 'InfoRequestEvent', created_at AS timestamp").
      where(created_at: start_date...).
      order(timestamp: :desc)

    case params[:event_type]
    when 'authority_change'
      connection.select_rows(authority_change_scope.to_sql)
    when 'info_request_event'
      connection.select_rows(info_request_event_scope.to_sql)
    else
      connection.select_rows("#{info_request_event_scope.unscope(:order).to_sql}
                              UNION
                              #{authority_change_scope.unscope(:order).to_sql}
                              ORDER by timestamp desc")
    end
  end
end

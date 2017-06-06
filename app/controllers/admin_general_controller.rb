# -*- encoding : utf-8 -*-
# app/controllers/admin_controller.rb:
# Controller for main admin pages.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminGeneralController < AdminController

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
    @old_unclassified = InfoRequest.where_old_unclassified.
                                      limit(20).
                                        is_searchable
    @holding_pen_messages = InfoRequest.
      includes(:incoming_messages => :raw_email).
        holding_pen_request.
          incoming_messages
    @public_request_tasks = [ @holding_pen_messages,
                              @error_message_requests,
                              @attention_requests,
                              @requires_admin_requests,
                              @old_unclassified ].
      any?{ |to_do_list| ! to_do_list.empty? }

    @blank_contacts = PublicBody.
      includes(:tags, :translations).
        where(:request_email => "").
          order(:updated_at).
            select { |pb| !pb.defunct? }

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
      any?{ |to_do_list| ! to_do_list.empty? }

    @attention_comments = Comment.
      where(:attention_requested => true).
        not_embargoed

    @comment_tasks = [ @attention_comments ].
      any?{ |to_do_list| ! to_do_list.empty? }

    @nothing_to_do = !@public_request_tasks &&
                     !@authority_tasks &&
                     !@comment_tasks

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

      @embargoed_request_tasks = [ @embargoed_requires_admin_requests,
                                   @embargoed_error_message_requests,
                                   @embargoed_attention_requests,
                                 ].any?{ |to_do_list| ! to_do_list.empty? }

      @embargoed_attention_comments = Comment.
                                        where(:attention_requested => true).
                                          embargoed

      @embargoed_comment_tasks = [
                                   @embargoed_attention_comments
                                 ].any?{ |to_do_list| ! to_do_list.empty? }
      @nothing_to_do = @nothing_to_do &&
                      !@embargoed_request_tasks &&
                      !@embargoed_comment_tasks
    end
  end

  def timeline
    # Recent events
    @events_title = "Events in last two days"
    date_back_to = Time.zone.now - 2.days
    if params[:hour]
      @events_title = "Events in last hour"
      date_back_to = Time.zone.now - 1.hour
    end
    if params[:day]
      @events_title = "Events in last day"
      date_back_to = Time.zone.now - 1.day
    end
    if params[:week]
      @events_title = "Events in last week"
      date_back_to = Time.zone.now - 1.week
    end
    if params[:month]
      @events_title = "Events in last month"
      date_back_to = Time.zone.now - 1.month
    end
    if params[:all]
      @events_title = "Events, all time"
      date_back_to = Time.zone.now - 1000.years
    end

    # Get an array of event attributes within the timespan in the format
    # [id, type_of_model, event_timestamp]
    # Note that the relevent date for InfoRequestEvents is creation, but
    # for PublicBodyVersions is update thoughout
    connection = InfoRequestEvent.connection
    timestamps = connection.select_rows("SELECT id,'InfoRequestEvent',
                                                    created_at AS timestamp
                                             FROM info_request_events
                                             WHERE created_at > '#{date_back_to.getutc}'
                                             UNION
                                             SELECT id, 'PublicBodyVersion',
                                                  updated_at AS timestamp
                                             FROM #{PublicBody.versioned_class.table_name}
                                             WHERE updated_at > '#{date_back_to.getutc}'
                                             ORDER by timestamp desc")
    @events = WillPaginate::Collection.create((params[:page] or 1), 100) do |pager|
      # create a hash for each model type being returned
      info_request_event_ids = {}
      public_body_version_ids = {}
      # get the relevant slice from the paginator
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
        includes(:public_body => :translations).
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

  def debug
    @admin_current_user = admin_current_user
    @current_commit = alaveteli_git_commit
    @current_branch = `git branch | perl -ne 'print $1 if /^\\* (.*)/'`
    @current_version = ALAVETELI_VERSION
    repo = `git remote show origin -n | perl -ne 'print $1 if m{Fetch URL: .*github\\.com[:/](.*)\\.git}'`
    @github_origin = "https://github.com/#{repo}/tree/"
    @request_env = request.env
  end

end

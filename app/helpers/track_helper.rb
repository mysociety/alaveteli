module TrackHelper

    def already_subscribed_notice(track_thing)
        case track_thing.track_type
        when 'request_updates'
            _("You are already subscribed to '{{link_to_request}}', a request",
                :link_to_request => request_link(track_thing.info_request))
        when 'all_new_requests'
            _('You are already subscribed to any <a href="{{new_requests_url}}">new requests</a>',
                :new_requests_url => request_list_path)
        when 'all_successful_requests'
            _('You are already subscribed to any <a href="{{successful_requests_url}}">successful requests</a>',
                :successful_requests_url => request_list_successful_path )
        when 'public_body_updates'
            _("You are already subscribed to '{{link_to_authority}}', a public authority",
                :link_to_authority => public_body_link(track_thing.public_body))
        when 'user_updates'
            _("You are already subscribed to '{{link_to_user}}', a person",
                :link_to_user => user_link(track_thing.tracked_user))
        when 'search_query'
            _('You are already subscribed to <a href="{{search_url}}">this search</a>',
                :search_url => search_path([track_thing.track_query, 'newest', 'advanced']))
        end
    end

end

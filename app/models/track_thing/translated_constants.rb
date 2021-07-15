class TrackThing
  module TranslatedConstants

    def self.track_types
      # { TRACK_TYPE => DESCRIPTION }
      { 'request_updates'         => _('Individual requests'),
        'all_new_requests'        => _('Many requests'),
        'all_successful_requests' => _('Many requests'),
        'public_body_updates'     => _('Public authorities'),
        'user_updates'            => _('People'),
        'search_query'            => _('Search queries') }
    end

  end
end

module Search
  module Adapters
    module Xapian
      ##
      # Centralised Xapian index configuration for all searchable models.
      # Called from config/initializers/acts_as_xapian.rb after the models
      # have been loaded.
      #
      module Indexing
        def self.configure!
          return unless ActsAsXapian.bindings_available

          configure_info_request_event!
          configure_public_body!
          configure_user!
        end

        def self.configure_info_request_event!
          InfoRequestEvent.acts_as_xapian \
            texts: [
              :search_text_main,
              :title
            ],
            values: [
              # for QueryParser range searches e.g. 01/01/2008..14/01/2008:
              [:created_at, 0, 'range_search', :date],
              # for sorting:
              [:created_at_numeric, 1, 'created_at', :number],
              # TODO: :number used for lack of :datetime support:
              [:described_at_numeric, 2, 'described_at', :number],
              [:request, 3, 'request_collapse', :string],
              [:request_title_collapse, 4, 'request_title_collapse', :string]
            ],
            terms: [
              [:calculated_state, 'S', 'status'],
              [:requested_by, 'B', 'requested_by'],
              [:requested_from, 'F', 'requested_from'],
              [:commented_by, 'C', 'commented_by'],
              [:request, 'R', 'request'],
              [:variety, 'V', 'variety'],
              [:latest_variety, 'K', 'latest_variety'],
              [:latest_status, 'L', 'latest_status'],
              [:waiting_classification, 'W', 'waiting_classification'],
              [:filetype, 'T', 'filetype'],
              [:tags, 'U', 'tag'],
              [:request_public_body_tags, 'X', 'request_public_body_tag']
            ],
            eager_load: [
              :outgoing_message,
              :comment,
              { info_request: [:user, :public_body, :censor_rules] }
            ],
            if: :indexed_by_search?
        end

        def self.configure_public_body!
          PublicBody.acts_as_xapian \
            texts: [:name, :short_name, :notes_as_string],
            values: [
              [:created_at_numeric, 1, 'created_at', :number]
            ],
            terms: [
              [:name_for_search, 'N', 'name'],
              [:variety, 'V', 'variety'],
              [:tag_array_for_search, 'U', 'tag']
            ],
            eager_load: [:translations]
        end

        def self.configure_user!
          User.acts_as_xapian \
            texts: [:name, :about_me],
            values: [
              [:created_at_numeric, 1, 'created_at', :number]
            ],
            terms: [[:variety, 'V', 'variety']],
            if: :indexed_by_search?
        end
      end
    end
  end
end

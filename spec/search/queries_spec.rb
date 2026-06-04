require 'spec_helper'

RSpec.describe ActsAsXapian::Search, :xapian do
  def search(models, query, opts = {})
    defaults = { offset: 0, limit: 25,
                 sort_by_prefix: 'created_at',
                 sort_by_ascending: true,
                 collapse_by_prefix: nil }
    ActsAsXapian::Search.new(models, query, defaults.merge(opts))
  end

  def search_results(models, query, opts = {})
    search(models, query, opts).results.map { |r| r[:model] }
  end

  describe 'text search' do
    it 'finds events matching a quoted phrase' do
      results = search_results([InfoRequestEvent], '"fancy dog"')
      expect(results).to eq(
        [info_request_events(:useless_outgoing_message_event)]
      )
    end

    it 'finds bodies and events matching multiple words' do
      results = search_results(
        [PublicBody, InfoRequestEvent], 'geraldine quango'
      )

      expect(results).to include(
        public_bodies(:geraldine_public_body)
      )
      expect(results).to include(
        info_request_events(:useless_incoming_message_event)
      )
    end

    it 'finds bodies, events and users' do
      results = search_results(
        [User, PublicBody, InfoRequestEvent], 'Bob'
      )

      expect(results).to include(
        public_bodies(:other_public_body)
      )
      expect(results).to include(
        info_request_events(:useless_outgoing_message_event)
      )
      expect(results).to include(
        users(:bob_smith_user)
      )
    end
  end

  describe 'prefix term filtering' do
    it 'finds events by requested_from prefix' do
      query = 'requested_from:tgq'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      geraldine = public_bodies(:geraldine_public_body)
      expect(requests).to all(
        satisfy { |r| r.public_body == geraldine }
      )
    end

    it 'finds events by requested_by prefix' do
      query = 'requested_by:bob_smith'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to match_array(
        users(:bob_smith_user).info_requests
      )
    end

    it 'finds events by request_public_body_tag prefix' do
      query = 'request_public_body_tag:popular_agency'
      results = search_results([InfoRequestEvent], query)

      tagged_body_ids = [
        public_bodies(:geraldine_public_body).id,
        public_bodies(:humpadink_public_body).id
      ]
      result_body_ids = results.
        map { |e| e.info_request.public_body_id }.uniq
      expect(result_body_ids).to all(be_in(tagged_body_ids))
    end

    it 'finds events by request url_title prefix' do
      query = 'request:why_do_you_have_such_a_fancy_dog'
      results = search_results([InfoRequestEvent], query)

      expect(results.map(&:info_request).uniq).to eq(
        [info_requests(:fancy_dog_request)]
      )
    end
  end

  describe 'model class filtering' do
    it 'returns only events when searching InfoRequestEvent' do
      results = search_results([InfoRequestEvent], 'bob')
      expect(results).to all(be_a(InfoRequestEvent))
    end

    it 'returns only users when searching User' do
      results = search_results([User], 'bob')
      expect(results).to eq([users(:bob_smith_user)])
      expect(results).to all(be_a(User))
    end

    it 'returns only bodies when searching PublicBody' do
      results = search_results([PublicBody], 'quango')
      expect(results).to include(
        public_bodies(:geraldine_public_body)
      )
      expect(results).to all(be_a(PublicBody))
    end

    it 'does not return unconfirmed users' do
      results = search_results([User], 'unconfirmed')
      expect(results).to be_empty
    end
  end

  describe 'status filtering' do
    it 'filters by latest_status' do
      query = 'bob ' \
              '(latest_status:successful OR latest_status:partially_successful)'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to match_array(
        [
          info_requests(:boring_request),
          info_requests(:another_boring_request)
        ]
      )
    end

    it 'filters by variety for comments' do
      query = 'daftest variety:comment'
      results = search_results([InfoRequestEvent], query)
      expect(results.size).to eq(1)
    end

    it 'returns nothing when variety excludes matching events' do
      query = 'daftest (variety:sent ' \
              'OR variety:followup_sent OR variety:response)'
      results = search_results([InfoRequestEvent], query)
      expect(results).to be_empty
    end
  end

  describe 'user contribution search' do
    it 'finds all contributions for a user' do
      query = 'requested_by:bob_smith'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to match_array(
        users(:bob_smith_user).info_requests
      )
    end

    it 'filters contributions by keyword' do
      query = 'requested_by:bob_smith money'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to match_array(
        [
          info_requests(:naughty_chicken_request),
          info_requests(:another_boring_request)
        ]
      )
    end

    it 'filters contributions by keyword and status' do
      query = 'requested_by:bob_smith money latest_status:waiting_response'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to match_array(
        [info_requests(:naughty_chicken_request)]
      )
    end
  end

  describe 'public body request listing' do
    it 'finds all events for a body' do
      query = '(variety:sent OR variety:followup_sent ' \
              'OR variety:response OR variety:comment) ' \
              'requested_from:tgq'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      geraldine = public_bodies(:geraldine_public_body)
      expect(requests).to match_array(
        InfoRequest.where(public_body_id: geraldine.id)
      )
    end

    it 'filters body events by successful status' do
      query = '(latest_status:successful ' \
              'OR latest_status:partially_successful) ' \
              'requested_from:tgq'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      geraldine = public_bodies(:geraldine_public_body)
      expect(requests).to match_array(
        InfoRequest.where(
          described_state: 'successful',
          public_body_id: geraldine.id
        )
      )
    end

    it 'finds events for a different body' do
      query = '(variety:sent OR variety:followup_sent ' \
              'OR variety:response OR variety:comment) ' \
              'requested_from:dfh'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      humpadink = public_bodies(:humpadink_public_body)
      expect(requests).to match_array(
        InfoRequest.where(public_body_id: humpadink.id)
      )
    end
  end

  describe 'feed queries' do
    it 'finds events for a tracked request sorted newest first' do
      query = 'request:why_do_you_have_such_a_fancy_dog'
      result = search([InfoRequestEvent], query)

      expect(result.matches_estimated).to eq(3)
      expect(result.results.size).to eq(3)
      expect(result.results[0][:model]).to eq(
        info_request_events(:silly_comment_event)
      )
      expect(result.results[1][:model]).to eq(
        info_request_events(:useless_incoming_message_event)
      )
      expect(result.results[2][:model]).to eq(
        info_request_events(:useless_outgoing_message_event)
      )
    end
  end

  describe 'collapsing' do
    it 'collapses multiple events from the same request' do
      query = 'request:why_do_you_have_such_a_fancy_dog'

      uncollapsed = search_results(
        [InfoRequestEvent], query
      )
      collapsed = search_results(
        [InfoRequestEvent], query,
        collapse_by_prefix: 'request_collapse'
      )

      expect(uncollapsed.size).to eq(3)
      expect(collapsed.size).to eq(1)
    end

    it 'collapses by request title to deduplicate' do
      query = 'variety:response ' \
              '(status:successful OR status:partially_successful)'

      uncollapsed = search_results(
        [InfoRequestEvent], query
      )
      collapsed = search_results(
        [InfoRequestEvent], query,
        collapse_by_prefix: 'request_title_collapse'
      )

      expect(collapsed.size).to be <= uncollapsed.size
    end
  end

  describe 'recent requests query' do
    it 'finds successful responses' do
      query = 'variety:response ' \
              '(status:successful OR status:partially_successful)'
      results = search_results([InfoRequestEvent], query)

      expect(results).to all(satisfy { |e|
        e.event_type == 'response' &&
          %w[successful partially_successful].
            include?(e.calculated_state)
      })
    end
  end

  describe 'request list queries' do
    it 'finds all request events' do
      query = '(variety:sent OR variety:followup_sent ' \
              'OR variety:response OR variety:comment)'
      results = search_results([InfoRequestEvent], query)

      expect(results).to all(satisfy { |e|
        %w[sent followup_sent response comment].
          include?(e.event_type)
      })
      expect(results.size).to be > 0
    end

    it 'filters by successful status' do
      query = '(latest_status:successful OR latest_status:partially_successful)'
      results = search_results([InfoRequestEvent], query)
      requests = results.map(&:info_request).uniq

      expect(requests).to all(satisfy { |r|
        %w[successful partially_successful].
          include?(r.described_state)
      })
    end

    it 'filters by awaiting status' do
      query = '(latest_status:waiting_response ' \
              'OR latest_status:waiting_clarification ' \
              'OR waiting_classification:true ' \
              'OR latest_status:internal_review ' \
              'OR latest_status:gone_postal ' \
              'OR latest_status:error_message ' \
              'OR latest_status:requires_admin)'
      results = search_results([InfoRequestEvent], query)

      expect(results.size).to be > 0
    end
  end

  describe 'spelling correction' do
    it 'suggests corrections for misspelled terms' do
      result = search([User], 'rob', limit: 5)
      expect(result.spelling_correction).to eq('bob')
    end
  end

  describe 'highlight words' do
    it 'returns words to highlight' do
      result = search([User], 'bob', limit: 5)
      words = result.words_to_highlight(
        include_original: true, regex: true
      )
      expect(words).to be_present
    end
  end
end

RSpec.describe TypeaheadSearch, :xapian do
  it 'finds authorities matching search terms' do
    typeahead = TypeaheadSearch.new(
      'Geraldine Humpadinking',
      model: PublicBody, page: 1, per_page: 25
    )
    result = typeahead.xapian_search
    bodies = result.results.map { |r| r[:model] }

    expect(bodies).to include(
      public_bodies(:geraldine_public_body),
      public_bodies(:humpadink_public_body)
    )
    expect(bodies.size).to eq(2)
  end
end

require 'spec_helper'

RSpec.describe Search::RecentRequests do
  describe '#call' do
    it 'backfills with sent events if fewer than five successful responses' do
      successful_event = FactoryBot.build(
        :info_request_event, event_type: 'response'
      )
      sent_event = FactoryBot.build(
        :info_request_event, event_type: 'sent'
      )

      successful_result = build_search_results(items: [successful_event])
      sent_result = build_search_results(items: [sent_event])

      searcher = double('FullTextSearch')
      allow(searcher).to receive(:results).
        and_return(successful_result, sent_result)
      allow(Search).to receive(:search).and_return(searcher)

      events, all_successful = described_class.new.call

      expect(events).to match_array([successful_event, sent_event])
      expect(all_successful).to be false
    end

    it 'sets all_successful flag for five or more successful responses' do
      events = Array.new(5) do
        FactoryBot.build(:info_request_event, event_type: 'response')
      end

      searcher = double('FullTextSearch')
      allow(searcher).to receive(:results).
        and_return(build_search_results(items: events))
      allow(Search).to receive(:search).and_return(searcher)

      result_events, all_successful = described_class.new.call

      expect(result_events.size).to eq(5)
      expect(all_successful).to be true
    end
  end
end

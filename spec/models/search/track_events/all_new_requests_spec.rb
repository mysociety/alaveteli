require 'spec_helper'

RSpec.describe Search::TrackEvents::AllNewRequests do
  let(:track_thing) { FactoryBot.create(:new_request_track) }

  subject(:events) do
    described_class.new(track_thing, sort_by: 'created_at', limit: 100).events
  end

  it { is_expected.to include(FactoryBot.create(:sent_event)) }
  it { is_expected.not_to include(FactoryBot.create(:response_event)) }
  it { is_expected.not_to include(FactoryBot.create(:followup_sent_event)) }
end

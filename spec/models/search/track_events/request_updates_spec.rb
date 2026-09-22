require 'spec_helper'

RSpec.describe Search::TrackEvents::RequestUpdates do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:track_thing) do
    FactoryBot.create(:request_update_track, info_request: info_request)
  end

  subject(:events) do
    described_class.new(track_thing, sort_by: 'created_at', limit: 100).events
  end

  it 'finds events on the tracked request' do
    is_expected.to include(
      FactoryBot.create(:response_event, info_request: info_request)
    )
  end

  it 'ignores events on any other request' do
    is_expected.not_to include(FactoryBot.create(:response_event))
  end
end

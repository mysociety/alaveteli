require 'spec_helper'

RSpec.describe Search::TrackEvents::AllSuccessfulRequests do
  let(:track_thing) { FactoryBot.create(:successful_request_track) }

  subject(:events) do
    described_class.new(track_thing, sort_by: 'described_at', limit: 100).events
  end

  def response(calculated_state)
    FactoryBot.create(:response_event, calculated_state: calculated_state)
  end

  it { is_expected.to include(response('successful')) }
  it { is_expected.to include(response('partially_successful')) }
  it { is_expected.not_to include(response('rejected')) }

  it 'ignores a successful state on another event type' do
    event = FactoryBot.create(:sent_event, calculated_state: 'successful')
    is_expected.not_to include(event)
  end
end

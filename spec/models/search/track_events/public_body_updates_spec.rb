require 'spec_helper'

RSpec.describe Search::TrackEvents::PublicBodyUpdates do
  let(:public_body) { FactoryBot.create(:public_body) }
  let(:track_thing) do
    FactoryBot.create(:public_body_track, public_body: public_body)
  end

  def track_events(track = track_thing)
    described_class.new(track, sort_by: 'described_at', limit: 100)
  end

  def event_on(body, factory = :sent_event, **options)
    FactoryBot.create(
      factory,
      info_request: FactoryBot.create(:info_request, public_body: body,
                                                     **options)
    )
  end

  it 'finds events on requests to the authority' do
    event = event_on(public_body)
    expect(track_events.events).to include(event)
  end

  it 'ignores requests to another authority' do
    event = event_on(FactoryBot.create(:public_body))
    expect(track_events.events).not_to include(event)
  end

  it 'ignores events on a hidden request' do
    event = event_on(public_body, prominence: 'hidden')
    expect(track_events.events).not_to include(event)
  end

  it 'orders newest described first' do
    older = event_on(public_body)
    newer = event_on(public_body)
    older.update!(last_described_at: 2.days.ago)
    newer.update!(last_described_at: 1.hour.ago)

    ids = track_events.events.map(&:id)
    expect(ids.index(newer.id)).to be < ids.index(older.id)
  end

  it 'applies the cap' do
    2.times { event_on(public_body) }
    capped = described_class.new(track_thing, sort_by: 'described_at', limit: 1)

    expect(capped.events.count).to eq(1)
  end

  it 'has no words to highlight' do
    expect(track_events.highlight_words).to eq([])
  end

  it 'loads the associations the digest walks' do
    event_on(public_body)
    expect(track_events.events.first.association(:info_request)).to be_loaded
  end

  context 'when the track names an event type' do
    let(:track_thing) do
      FactoryBot.create(
        :public_body_track, public_body: public_body, variety: 'comment'
      )
    end

    it 'finds only that type' do
      comment = FactoryBot.create(
        :comment_event,
        info_request: FactoryBot.create(:info_request, public_body: public_body)
      )
      sent = event_on(public_body)

      expect(track_events.events).to include(comment)
      expect(track_events.events).not_to include(sent)
    end
  end
end

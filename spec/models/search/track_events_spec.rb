require 'spec_helper'

RSpec.describe Search::TrackEvents do
  describe '.for' do
    TrackThing::TranslatedConstants.track_types.each_key do |track_type|
      it "returns the #{track_type} strategy" do
        track_thing = FactoryBot.build(:track_thing, track_type: track_type)

        expect(described_class.for(track_thing, sort_by: 'created_at',
                                                limit: 25)).
          to be_a(described_class.strategy_for(track_type))
      end
    end

    it 'raises for a track type with no strategy' do
      track_thing = FactoryBot.build(:track_thing)
      allow(track_thing).to receive(:track_type).and_return('nonsense')

      expect {
        described_class.for(track_thing, sort_by: 'created_at', limit: 25)
      }.to raise_error(ArgumentError, /nonsense/)
    end
  end

  describe '#events' do
    it 'is not implemented on the base class' do
      track_events = described_class.new(FactoryBot.build(:track_thing),
                                         sort_by: 'created_at', limit: 25)

      expect { track_events.events }.to raise_error(NotImplementedError)
    end
  end
end

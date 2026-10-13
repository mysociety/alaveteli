require 'spec_helper'

RSpec.describe Search::TrackEvents do
  def track_events_for(track_thing)
    described_class.for(track_thing, sort_by: 'created_at', limit: 25)
  end

  describe '.for' do
    TrackThing::TranslatedConstants.track_types.each_key do |track_type|
      it "returns the #{track_type} strategy" do
        track_thing = FactoryBot.build(:track_thing, track_type: track_type)

        with_feature_enabled(:database_backed_alerts) do
          expect(track_events_for(track_thing)).
            to be_a(described_class.strategy_for(track_type))
        end
      end
    end

    it 'raises for a track type with no strategy' do
      track_thing = FactoryBot.build(:track_thing)
      allow(track_thing).to receive(:track_type).and_return('nonsense')

      expect { track_events_for(track_thing) }.
        to raise_error(ArgumentError, /nonsense/)
    end

    context 'for a type that has left the search index' do
      let(:track_thing) { FactoryBot.build(:public_body_track) }

      it 'falls back to the index while the feature is off' do
        expect(track_events_for(track_thing)).
          to be_a(Search::TrackEvents::Index)
      end

      it 'uses the database once the feature is on' do
        with_feature_enabled(:database_backed_alerts) do
          expect(track_events_for(track_thing)).
            to be_a(Search::TrackEvents::PublicBodyUpdates)
        end
      end
    end

    context 'for a type still on the search index' do
      let(:track_thing) { FactoryBot.build(:search_track) }

      it 'uses the index whatever the feature says' do
        with_feature_enabled(:database_backed_alerts) do
          expect(track_events_for(track_thing)).
            to be_a(Search::TrackEvents::Index)
        end
      end
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

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

    context 'when a type has a database finder' do
      before do
        stub_const('Search::TrackEvents::SearchQuery', database_finder)
      end

      let(:database_finder) { Class.new(Search::TrackEvents) }
      let(:track_thing) { FactoryBot.build(:search_track) }

      subject do
        described_class.for(track_thing, sort_by: 'created_at', limit: 25)
      end

      it 'uses the search index while the feature is off' do
        is_expected.to be_a(Search::TrackEvents::Index)
      end

      it 'uses the database once the feature is on' do
        with_feature_enabled(:database_backed_alerts) do
          is_expected.to be_a(database_finder)
        end
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

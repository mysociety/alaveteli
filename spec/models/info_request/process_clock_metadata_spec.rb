require 'spec_helper'

RSpec.describe InfoRequest, 'process_clock_metadata' do
  let(:info_request) { FactoryBot.create(:info_request) }

  describe '#process_clock_metadata' do
    it 'returns an empty hash by default' do
      expect(info_request.process_clock_metadata).to eq({})
    end

    context 'when a theme defines theme_process_clock_metadata' do
      before do
        info_request.define_singleton_method(:theme_process_clock_metadata) do
          { 'clock' => 'active', 'process_state' => 'RECEIVED' }
        end
      end

      it 'returns the theme metadata' do
        expect(info_request.process_clock_metadata).
          to eq('clock' => 'active', 'process_state' => 'RECEIVED')
      end

      it 'includes the metadata in json_for_api when present' do
        json = info_request.json_for_api(false)
        expect(json[:process_clock_metadata]).
          to eq('clock' => 'active', 'process_state' => 'RECEIVED')
      end
    end

    it 'omits process_clock_metadata from json_for_api when empty' do
      json = info_request.json_for_api(false)
      expect(json).not_to have_key(:process_clock_metadata)
    end
  end
end

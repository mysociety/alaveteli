# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::InfoRequestsHelper do

  include AlaveteliPro::InfoRequestsHelper

  describe '#phase_and_state' do

    context 'when the phase and state description are the same(ignoring
            capitalization)' do
      let(:info_request){ FactoryGirl.create(:info_request_with_incoming) }

      it 'returns the phase description' do
        expect(phase_and_state(info_request)).to eq 'Awaiting response'
      end

    end

    context 'when the phase and state description are different' do
      let(:info_request){ FactoryGirl.create(:successful_request) }

      it 'returns the phase and state hyphenated' do
        expect(phase_and_state(info_request)).to eq 'Complete - successful'
      end

    end

  end

end

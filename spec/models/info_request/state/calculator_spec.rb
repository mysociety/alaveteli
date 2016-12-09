# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequest::State::Calculator do

  describe '#phase' do
    let(:info_request){ FactoryGirl.create(:info_request) }

    it 'returns :awaiting_response when the request is in state "waiting_response"' do
      expect(described_class.new(info_request).phase)
        .to eq(:awaiting_response)
    end

    it 'returns :clarification_needed when the request is in state "waiting_clarification"' do
      info_request.set_described_state('waiting_clarification')
      expect(described_class.new(info_request).phase)
        .to eq(:clarification_needed)
    end

    it 'returns :complete when the request is in state "not_held"' do
      info_request.set_described_state('not_held')
      expect(described_class.new(info_request).phase)
        .to eq(:complete)
    end

    it 'returns :other when the request is in state "gone_postal"' do
      info_request.set_described_state('gone_postal')
      expect(described_class.new(info_request).phase)
        .to eq(:other)
    end

    it 'returns :response_received when the request is awaiting description' do
      info_request.awaiting_description = true
      info_request.save
      expect(described_class.new(info_request).phase)
        .to eq(:response_received)
    end

  end

end

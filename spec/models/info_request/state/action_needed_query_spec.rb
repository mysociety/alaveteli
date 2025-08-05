# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequest::State::ActionNeededQuery do
  describe '#call' do
    it 'includes those that have a new response, need clarification
        and are overdue or very_overdue' do
      response_received = FactoryBot.create(:awaiting_description)
      needing_clarification = FactoryBot.create(:waiting_clarification_info_request)
      overdue = FactoryBot.create(:overdue_request)
      very_overdue = FactoryBot.create(:very_overdue_request)
      results = described_class.new.call
      expect(results.include?(response_received)).to be true
      expect(results.include?(needing_clarification)).to be true
      expect(results.include?(overdue)).to be true
      expect(results.include?(very_overdue)).to be true
    end

    it 'excludes those that are waiting for a response or successful' do
      waiting_response = FactoryBot.create(:info_request)
      successful = FactoryBot.create(:successful_request)
      results = described_class.new.call
      expect(results.include?(waiting_response)).to be false
      expect(results.include?(successful)).to be false
    end
  end
end

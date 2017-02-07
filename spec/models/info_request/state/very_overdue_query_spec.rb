# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::State::VeryOverdueQuery do

  describe '#call' do
    let(:info_request) { FactoryGirl.create(:info_request) }

    it 'excludes those that are waiting for a response where the response
        is past due' do
      time_travel_to(Date.parse('2015-10-01')){ info_request }
      time_travel_to(Date.parse('2015-10-31')) do
        expect(described_class.new.call.include?(info_request)).to be false
      end
    end

    it 'includes those that are waiting for a response where the response
        is very overdue' do
      time_travel_to(Date.parse('2015-10-01')){ info_request }
      time_travel_to(Date.parse('2015-11-30')) do
        expect(described_class.new.call.include?(info_request)).to be true
      end
    end

    it 'excludes those that are not waiting for a response' do
      expect(described_class.new.call.include?(info_request))
        .to be false
    end

  end
end

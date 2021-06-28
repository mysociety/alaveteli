require 'spec_helper'

describe InfoRequest::State::VeryOverdueQuery do

  describe '#call' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'excludes those that are waiting for a response where the response
        is past due' do
      travel_to(Time.zone.parse('2015-10-01')) { info_request }
      travel_to(Time.zone.parse('2015-10-31')) do
        expect(described_class.new.call.include?(info_request)).to be false
      end
    end

    it 'includes those that are waiting for a response where the response
        is very overdue' do
      travel_to(Time.zone.parse('2015-10-01')) { info_request }
      travel_to(Time.zone.parse('2015-11-30')) do
        expect(described_class.new.call.include?(info_request)).to be true
      end
    end

    it 'excludes those that are not waiting for a response' do
      expect(described_class.new.call.include?(info_request))
        .to be false
    end

    it 'excludes those that are waiting for description' do
      travel_to(Time.zone.parse('2015-10-01')) do
        info_request
        info_request.awaiting_description = true
        info_request.save!
      end
      travel_to(Time.zone.parse('2015-11-30')) do
        expect(described_class.new.call.include?(info_request))
          .to be false
      end
    end

  end
end

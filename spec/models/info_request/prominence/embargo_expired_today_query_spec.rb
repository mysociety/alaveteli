# -*- encoding : utf-8 -*-
require 'spec_helper.rb'

describe InfoRequest::Prominence::EmbargoExpiredTodayQuery do

  describe '#call' do
    let(:info_request) { info_request = FactoryBot.create(:info_request) }

    it 'excludes requests that are currently under embargo' do
      embargo = FactoryBot.create(:embargo,
                                  publish_at: Time.now + 4.days)

      expect(described_class.new.call).not_to include embargo.info_request
    end

    it 'excludes requests where the embargo expired the day before' do
      time_travel_to(4.days.ago) do
        embargo = FactoryBot.create(:embargo,
                                    info_request: info_request,
                                    publish_at: Time.zone.now + 2.days)
      end
      time_travel_to(1.day.ago) { AlaveteliPro::Embargo.expire_publishable }

      expect(described_class.new.call).not_to include info_request
    end

    it 'includes requests that have expired since the start of the day' do
      time_travel_to(4.days.ago) do
        embargo = FactoryBot.create(:embargo,
                                    info_request: info_request,
                                    publish_at: Time.zone.now + 3.days)
      end
      AlaveteliPro::Embargo.expire_publishable

      expect(described_class.new.call).to include info_request
    end

  end

end

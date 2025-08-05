# -*- encoding : utf-8 -*-
require 'spec_helper.rb'

describe InfoRequest::Prominence::EmbargoExpiringQuery do

  describe '#call' do

    it 'includes requests that have embargoes expiring within a week' do
      embargo = FactoryBot.create(:embargo,
                                  :publish_at => Time.now + 4.days)
      expect(described_class.new.call).to include embargo.info_request
    end

    it 'excludes requests that have embargoes expiring in over a week' do
      embargo = FactoryBot.create(:embargo,
                                  :publish_at => Time.now + 8.days)
      expect(described_class.new.call).not_to include embargo.info_request
    end

    it 'excludes requests without an embargo' do
      info_request = FactoryBot.create(:info_request)
      expect(described_class.new.call).not_to include info_request
    end

  end
end

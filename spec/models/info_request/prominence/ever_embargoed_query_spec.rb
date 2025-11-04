require 'spec_helper'

RSpec.describe InfoRequest::Prominence::EverEmbargoedQuery do
  describe '#call' do
    subject { described_class.new.call }

    it 'limits the requests to those that have ever been embargoed' do
      info_request = FactoryBot.create(:info_request)
      embargoed_request = FactoryBot.create(:embargoed_request)
      re_embargoed_request = FactoryBot.create(:re_embargoed_request)
      embargo_expired_request = FactoryBot.create(:embargo_expired_request)

      is_expected.to_not include info_request
      is_expected.to include embargoed_request
      is_expected.to include re_embargoed_request
      is_expected.to include embargo_expired_request
    end
  end
end

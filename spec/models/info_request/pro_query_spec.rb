# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequest::ProQuery do

  describe '#call' do

    it 'includes requests made by pro users' do
      pro_user = FactoryGirl.create(:pro_user)
      info_request = FactoryGirl.create(:info_request, :user => pro_user)
      expect(described_class.new.call.include?(info_request)).to be true
    end

    it 'excludes requests made by non-pro users' do
      info_request = FactoryGirl.create(:info_request)
      expect(described_class.new.call.include?(info_request)).to be false
    end

    it 'excludes external requests' do
      external_request = FactoryGirl.create(:external_request)
      expect(described_class.new.call.include?(external_request))
        .to be false
    end

  end
end

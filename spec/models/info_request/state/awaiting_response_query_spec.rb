# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::State::AwaitingResponseQuery do

  describe '#call' do

    it 'includes those that are waiting for a response,
        and not waiting for description' do
      info_request = FactoryGirl.create(:info_request)
      expect(described_class.new.call.include?(info_request)).to be true
    end

    it 'excludes those that are waiting for description' do
      old_unclassified_request = FactoryGirl.create(:old_unclassified_request)
      expect(described_class.new.call.include?(old_unclassified_request))
        .to be false
    end

  end
end

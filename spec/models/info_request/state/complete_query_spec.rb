# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::State::CompleteQuery do

  describe '#call' do
    let(:info_request){ FactoryBot.create(:successful_request) }

    it 'includes those that are successful,
        and not waiting for description' do
      expect(described_class.new.call.include?(info_request)).to be true
    end

    it 'excludes those that are waiting for description' do
      info_request.awaiting_description = true
      info_request.save!
      expect(described_class.new.call.include?(info_request))
        .to be false
    end

  end
end

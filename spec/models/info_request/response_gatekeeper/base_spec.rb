# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::ResponseGatekeeper::Base do

  describe '.new' do

    it 'requires an info_request' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it 'assigns the info_request' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.info_request).to eq(info_request)
    end

    it 'sets a default value for allow' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.allow).to eq(true)
    end

    it 'sets a default value for reason' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.reason).to be_nil
    end

  end

  describe '#info_request' do

    it 'returns the info_request' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.info_request).to eq(info_request)
    end

  end

  describe '#allow?' do

    it 'requires an email' do
      gatekeeper = described_class.new(FactoryGirl.build(:info_request))
      expect{ gatekeeper.allow? }.to raise_error(ArgumentError)
    end

    it 'allows all emails' do
      email = double
      gatekeeper = described_class.new(FactoryGirl.build(:info_request))
      expect(gatekeeper.allow?(email)).to eq(true)
    end

  end

  describe '#rejection_action' do

    it 'delegates to the info_request' do
      info_request = FactoryGirl.
        build(:info_request, :handle_rejected_responses => 'holding_pen')
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.rejection_action).to eq('holding_pen')
    end

  end

end

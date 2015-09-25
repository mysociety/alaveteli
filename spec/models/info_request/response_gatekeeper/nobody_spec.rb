# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::ResponseGatekeeper::Nobody do

  it 'inherits from Base' do
    expect(described_class.superclass).
      to eq(InfoRequest::ResponseGatekeeper::Base)
  end

  describe '.new' do

    it 'requires an info_request' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it 'assigns the info_request' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.info_request).to eq(info_request)
    end

    it 'does not allow responses' do
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.allow).to eq(false)
    end

    it 'sets a default reason' do
      reason = _('This request has been set by an administrator to ' \
                 '"allow new responses from nobody"')
      info_request = FactoryGirl.build(:info_request)
      gatekeeper = described_class.new(info_request)
      expect(gatekeeper.reason).to eq(reason)
    end

  end

end

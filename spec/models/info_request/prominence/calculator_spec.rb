# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::Prominence::Calculator do

  let(:info_request){ FactoryGirl.build(:info_request) }

  def expect_value(prominence, method, value)
    info_request.prominence = prominence
    expect(described_class.new(info_request).send(method)).to eq(value)
  end

  describe '#is_public?' do

    it 'returns true if its prominence is normal' do
      expect_value('normal', :is_public?, true)
    end

    it 'returns true if its prominence is backpage' do
      expect_value('backpage', :is_public?, true)
    end

    it 'returns false if its prominence is hidden' do
      expect_value('hidden', :is_public?, false)
    end

    it 'returns false if its prominence is requester_only' do
       expect_value('requester_only', :is_public?, false)
    end

  end

  describe '#is_searchable?' do

    it 'returns true if its prominence is normal' do
      expect_value('normal', :is_searchable?, true)
    end

    it 'returns false if its prominence is backpage' do
      expect_value('backpage', :is_searchable?, false)
    end

    it 'returns false if its prominence is hidden' do
      expect_value('hidden', :is_searchable?, false)
    end

    it 'returns false if its prominence is requester_only' do
       expect_value('requester_only', :is_searchable?, false)
    end

  end

  describe '#is_private?' do

    it 'returns false if its prominence is normal' do
      expect_value('normal', :is_private?, false)
    end

    it 'returns false if its prominence is backpage' do
      expect_value('backpage', :is_private?, false)
    end

    it 'returns true if its prominence is hidden' do
      expect_value('hidden', :is_private?, true)
    end

    it 'returns true if its prominence is requester_only' do
       expect_value('requester_only', :is_private?, true)
    end

  end

  describe '#is_requester_only?' do

    it 'returns false if its prominence is normal' do
      expect_value('normal', :is_requester_only?, false)
    end

    it 'returns false if its prominence is backpage' do
      expect_value('backpage', :is_requester_only?, false)
    end

    it 'returns false if its prominence is hidden' do
      expect_value('hidden', :is_requester_only?, false)
    end

    it 'returns true if its prominence is requester_only' do
       expect_value('requester_only', :is_requester_only?, true)
    end

  end

  describe '#is_hidden?' do

    it 'returns false if its prominence is normal' do
      expect_value('normal', :is_hidden?, false)
    end

    it 'returns false if its prominence is backpage' do
      expect_value('backpage', :is_hidden?, false)
    end

    it 'returns true if its prominence is hidden' do
      expect_value('hidden', :is_hidden?, true)
    end

    it 'returns false if its prominence is requester_only' do
       expect_value('requester_only', :is_hidden?, false)
    end

  end

  describe '#to_s' do

    it 'returns the prominence of the request' do
      expect_value('normal', :to_s, 'normal')
    end

  end

end

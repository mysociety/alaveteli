# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::ActivityList::Item do

  describe '.new' do
    it 'requires an event argument' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it 'assigns the event argument' do
      event = FactoryGirl.create(:info_request_event)
      list = described_class.new(event)
      expect(list.event).to eq event
    end
  end
end

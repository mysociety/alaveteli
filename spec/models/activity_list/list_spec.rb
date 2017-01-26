# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActivityList::List do

  describe '.new' do
    it 'requires a user, page and per_page arguments' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it 'assigns the user, page and per_page arguments' do
      user = FactoryGirl.create(:user)
      list = described_class.new(user, 1, 10)
      expect(list.user).to eq user
      expect(list.page).to eq 1
      expect(list.per_page).to eq 10
    end

  end

  describe '#event_types' do
    let(:user){ FactoryGirl.create(:user) }

    it 'returns an array' do
      expect(described_class.new(user, 1, 10).event_types.class).to eq Array
    end

    it 'includes a "sent" event type' do
      expect(described_class.new(user, 1, 10).
               event_types.
                 include?("sent")).to be true
    end

  end

  describe '#events' do

    it "returns the user's info_request_events if
        included in the event types" do
      user = FactoryGirl.create(:user)
      info_request = FactoryGirl.create(:info_request, :user => user)
      edit_event = FactoryGirl.create(:edit_event,
                                      :info_request => info_request)
      list = described_class.new(user, 1, 10)
      expect(list.events).
        to eq([info_request.last_event_forming_initial_request])
    end

  end

  describe '#current_items' do

    it 'returns an array of items representing the current page of events' do
      user = FactoryGirl.create(:user)
      info_request = FactoryGirl.create(:info_request, :user => user)
      response_event = FactoryGirl.create(:response_event,
                                          :info_request => info_request)
      comment_event = FactoryGirl.create(:comment_event,
                                         :info_request => info_request)
      resent_event = FactoryGirl.create(:resent_event,
                                        :info_request => info_request)
      list = described_class.new(user, 1, 2)
      expect(list.current_items.first).to be_a(ActivityList::RequestResent)
      expect(list.current_items.second).to be_a(ActivityList::Comment)
      list = described_class.new(user, 2, 2)
      expect(list.current_items.first).to be_a(ActivityList::NewResponse)
      expect(list.current_items.second).to be_a(ActivityList::RequestSent)
    end

  end

end

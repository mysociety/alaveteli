# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ToDoList::List do

  describe '.new' do

    it 'requires a user' do
      expect{ described_class.new }.to raise_error(ArgumentError)
    end

    it 'assigns the user' do
      user = FactoryGirl.create(:user)
      list = described_class.new(user)
      expect(list.user).to eq user
    end

  end

  describe '#items' do

    it 'returns to do list items' do
      user = FactoryGirl.create(:user)
      described_class.new(user).items.each do |item|
        expect(item).to be_kind_of ToDoList::Item
      end
    end

  end

  describe '#active_items' do

    it 'returns items whose count is greater than zero' do
      user = FactoryGirl.create(:user)
      new_response = double('new_response', :count => 1)
      expiring_embargo = double('expiring_embargo', :count => 0)
      overdue_request = double('overdue_request', :count => 2)
      allow(ToDoList::NewResponse).to receive(:new)
        .and_return(new_response)
      allow(ToDoList::ExpiringEmbargo).to receive(:new)
        .and_return(expiring_embargo)
      allow(ToDoList::OverdueRequest).to receive(:new)
        .and_return(overdue_request)

      expect(described_class.new(user).active_items)
        .to eq([new_response, overdue_request])
    end

  end

end

# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: spam_addresses
#
#  id         :integer          not null, primary key
#  email      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe SpamAddress do

  describe '.new' do

    it 'requres an email address' do
      expect(SpamAddress.new).not_to be_valid
      expect(SpamAddress.new(:email => 'spam@example.org')).to be_valid
    end

    it 'must have a unique email address' do
      existing = FactoryGirl.create(:spam_address)
      expect(SpamAddress.new(:email => existing.email)).not_to be_valid
    end

  end

  describe '.spam?' do

    before(:each) do
      @spam_address = FactoryGirl.create(:spam_address)
    end

    it 'is a spam address if the address is stored' do
      expect(SpamAddress.spam?(@spam_address.email)).to be true
    end

    it 'is not a spam address if the adress is not stored' do
      expect(SpamAddress.spam?('genuine-email@example.com')).to be false
    end

    describe 'when accepting an array of emails' do

      it 'is spam if any of the emails are stored' do
        emails = ['genuine-email@example.com', @spam_address.email]
        expect(SpamAddress.spam?(emails)).to be true
      end

      it 'is not spam if none of the emails are stored' do
        emails = ['genuine-email@example.com', 'genuine-email@example.org']
        expect(SpamAddress.spam?(emails)).to be false
      end

    end

  end

end

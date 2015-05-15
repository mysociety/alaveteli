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

    describe :new do

        it 'requres an email address' do
            SpamAddress.new().should_not be_valid
            SpamAddress.new(:email => 'spam@example.org').should be_valid
        end

        it 'must have a unique email address' do
            existing = FactoryGirl.create(:spam_address)
            SpamAddress.new(:email => existing.email).should_not be_valid
        end

    end

    describe '.spam?' do

        before(:each) do
            @spam_address = FactoryGirl.create(:spam_address)
        end

        it 'is a spam address if the address is stored' do
           SpamAddress.spam?(@spam_address.email).should be_true
        end

        it 'is not a spam address if the adress is not stored' do
            SpamAddress.spam?('genuine-email@example.com').should be_false
        end

        describe 'when accepting an array of emails' do

            it 'is spam if any of the emails are stored' do
                emails = ['genuine-email@example.com', @spam_address.email]
                SpamAddress.spam?(emails).should be_true
            end
 
            it 'is not spam if none of the emails are stored' do
                emails = ['genuine-email@example.com', 'genuine-email@example.org']
                SpamAddress.spam?(emails).should be_false
            end
 
        end

    end

end

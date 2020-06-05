# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: spam_addresses
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe SpamAddress do
  it { is_expected.to strip_attribute(:email) }

  describe '.new' do

    it 'requres an email address' do
      expect(SpamAddress.new).not_to be_valid
      expect(SpamAddress.new(:email => 'spam@example.org')).to be_valid
    end

    it 'must have a unique email address' do
      existing = FactoryBot.create(:spam_address)
      expect(SpamAddress.new(:email => existing.email)).not_to be_valid
    end

  end

  describe '.spam?' do

    before(:each) do
      @spam_address = FactoryBot.create(:spam_address)
    end

    it 'is a spam address if the address is stored' do
      expect(SpamAddress.spam?(@spam_address.email)).to be true
    end

    it 'is case insensitive' do
      expect(SpamAddress.spam?(@spam_address.email.swapcase)).to be true
    end

    it 'is not a spam address if the adress is not stored' do
      expect(SpamAddress.spam?('genuine-email@example.com')).to be false
    end

    it 'is not a spam address if the address is empty' do
      expect(SpamAddress.spam?(nil)).to be false
    end

    describe 'when accepting an array of emails' do

      it 'is spam if any of the emails are stored' do
        emails = ['genuine-email@example.com', @spam_address.email.swapcase]
        expect(SpamAddress.spam?(emails)).to be true
      end

      it 'is not spam if none of the emails are stored' do
        emails = ['genuine-email@example.com', 'genuine-email@example.org']
        expect(SpamAddress.spam?(emails)).to be false
      end

    end

  end

  describe '#save' do
    subject { spam_address.save }

    context 'with a mixed-case email' do
      let(:spam_address) { described_class.new(email: 'FoO@eXaMpLe.OrG') }

      it 'downcases the email' do
        subject
        expect(spam_address.email).to eq('foo@example.org')
      end
    end
  end
end

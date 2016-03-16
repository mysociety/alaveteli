# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ReminderMailer do

  describe :public_holidays do

    it 'correctly quotes the name in a "from" address' do
      expect(ReminderMailer.public_holidays("A,B,C.",
                                     "test@example.com",
                                     "test")['from'].to_s).to eq('"A,B,C." <test@example.com>')
    end

    it 'sets the "Reply-To" header header to the sender' do
      expect(ReminderMailer.public_holidays("test sender",
                                     "test@example.com",
                                     "test").header['Reply-To'].to_s).to eq('test sender <test@example.com>')
    end

    it 'sets the "Return-Path" header to the blackhole address' do
      expect(ReminderMailer.public_holidays("test sender",
                                     "test@example.com",
                                     "test").header['Return-Path'].to_s).to eq('do-not-reply-to-this-address@localhost')
    end

  end

end

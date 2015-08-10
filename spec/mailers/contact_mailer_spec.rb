# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContactMailer do

  describe :to_admin_message do

    it 'correctly quotes the name in a "from" address' do
      expect(ContactMailer.to_admin_message("A,B,C.",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil)['from'].to_s).to eq('"A,B,C." <test@example.com>')
    end

    it 'sets the "Reply-To" header header to the sender' do
      expect(ContactMailer.to_admin_message("test sender",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil).header['Reply-To'].to_s).to eq('test sender <test@example.com>')
    end

    it 'sets the "Return-Path" header to the blackhole address' do
      expect(ContactMailer.to_admin_message("test sender",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil).header['Return-Path'].to_s).to eq('do-not-reply-to-this-address@localhost')
    end

  end

end

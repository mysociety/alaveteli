# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContactMailer do

  describe :to_admin_message do

    it 'correctly quotes the name in a "from" address' do
      expect(ContactMailer.to_admin_message("A,B,C.",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil)['from'].to_s).to \
      eq('"A,B,C." <do-not-reply-to-this-address@localhost>')
    end

    it 'sets the "From" address to the blackhole address' do
     expect(ContactMailer.to_admin_message("test sender",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil)
      .header['from'].to_s).to \
      eq('test sender <do-not-reply-to-this-address@localhost>')
    end

    it 'sets the "Reply-To" header header to the sender' do
      expect(ContactMailer.to_admin_message("test sender",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil)
        .header['Reply-To'].to_s).to eq('test sender <test@example.com>')
    end

    it 'sets the "Return-Path" header to the blackhole address' do
      expect(ContactMailer.to_admin_message("test sender",
                                     "test@example.com",
                                     "test",
                                     "test", nil, nil, nil)
        .header['Return-Path'].to_s).to \
        eq('do-not-reply-to-this-address@localhost')
    end

    it 'does not add HTMLEntities to an update public body email subject' do
      public_body = FactoryGirl.create(:public_body, :name => "Apostrophe's")
      change_request = FactoryGirl.create(:update_body_request,
                                          :public_body => public_body)
      expect(ContactMailer.update_public_body_email(change_request).subject).
        to eq("Update email address - Apostrophe's")
    end

    it 'does not add HTMLEntities to an add public body email subject' do
      change_request = FactoryGirl.create(:add_body_request,
                                          :public_body_name => "Apostrophe's")
      expect(ContactMailer.add_public_body(change_request).subject).
        to eq("Add authority - Apostrophe's")
    end

  end

end

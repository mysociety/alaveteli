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

    context "when the user is a pro user" do
      let(:pro_user) { FactoryBot.create(:pro_user) }

      it "sends messages to the pro contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.to_admin_message(pro_user.name,
                                                   pro_user.email,
                                                   "test subject",
                                                   "test message",
                                                   pro_user,
                                                   nil,
                                                   nil)
          expect(message.to).to eq [AlaveteliConfiguration.pro_contact_email]
        end
      end
    end

    context "when the user is a normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "sends messages to the normal contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.to_admin_message(user.name,
                                                   user.email,
                                                   "test subject",
                                                   "test message",
                                                   user,
                                                   nil,
                                                   nil)
          expect(message.to).to eq [AlaveteliConfiguration.contact_email]
        end
      end
    end

    context "when no user is a provided" do
      let(:user) { FactoryBot.create(:user) }

      it "sends messages to the normal contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.to_admin_message(user.name,
                                                   user.email,
                                                   "test subject",
                                                   "test message",
                                                   nil,
                                                   nil,
                                                   nil)
          expect(message.to).to eq [AlaveteliConfiguration.contact_email]
        end
      end
    end

  end

  describe "#from_admin_message" do
    context "when the receiving user is a pro user" do
      let(:pro_user) { FactoryBot.create(:pro_user) }

      it "sends messages from the pro contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.from_admin_message(pro_user.name,
                                                     pro_user.email,
                                                     "test subject",
                                                     "test message")
          expect(message.from).to eq [AlaveteliConfiguration.pro_contact_email]
        end
      end
    end

    context "when the receiving user is a normal user" do
      let(:user) { FactoryBot.create(:user) }

      it "sends messages from the normal contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.from_admin_message(user.name,
                                                     user.email,
                                                     "test subject",
                                                     "test message")
          expect(message.from).to eq [AlaveteliConfiguration.contact_email]
        end
      end
    end

    context "when no receiving user can be found" do
      it "sends messages from the normal contact address" do
        with_feature_enabled(:alaveteli_pro) do
          message = ContactMailer.from_admin_message("test user name",
                                                     "no-such-user@localhost",
                                                     "test subject",
                                                     "test message")
          expect(message.from).to eq [AlaveteliConfiguration.contact_email]
        end
      end
    end
  end

end

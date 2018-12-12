# -*- encoding : utf-8 -*-
require 'spec_helper'

describe PublicBodyChangeRequestMailer do
  describe '.change_request_message' do
    context 'when use_new_body_template is true' do
      it 'uses the add_public_body template' do
        change_request = FactoryBot.create(:add_body_request)
        mail = described_class.change_request_message(change_request, true)
        expect(mail.body.to_s).to match(/would like a new authority added to/)
      end
    end

    context 'when use_new_body_template is false' do
      it 'uses the update_public_body_email template' do
        change_request = FactoryBot.create(:update_body_request)
        mail = described_class.change_request_message(change_request, false)
        expect(mail.body.to_s).to match(/would like the email address for/)
      end
    end

    it 'sets the Reply-To header to the change request user' do
      user = FactoryBot.create(:user, name: 'Jim', email: 'jim@localhost')
      change_request = FactoryBot.create(:add_body_request, user: user)
      mail = described_class.change_request_message(change_request, true)
      expect(mail['Reply-To'].value).to include('Jim <jim@localhost>')
    end

    it 'sets the from address to the blackhole email' do
      user = FactoryBot.create(:user, name: 'Bob')
      change_request = FactoryBot.create(:add_body_request, user: user)
      mail = described_class.change_request_message(change_request, true)
      expect(mail['From'].value).
        to include('Bob <do-not-reply-to-this-address@localhost>')
    end

    it 'sends the mail to the admin team' do
      change_request = FactoryBot.create(:add_body_request)
      mail = described_class.change_request_message(change_request, true)
      expect(mail['To'].value).
        to include('Alaveteli Webmaster <postmaster@localhost>')
    end

    it 'does not add HTMLEntities to an update public body email subject' do
      public_body = FactoryBot.create(:public_body, :name => "Apostrophe's")
      change_request = FactoryBot.create(:update_body_request,
                                         :public_body => public_body)
      expect(
        described_class.change_request_message(change_request, false).subject
      ).to eq("Update email address - Apostrophe's")
    end

    it 'does not add HTMLEntities to an add public body email subject' do
      change_request = FactoryBot.create(:add_body_request,
                                         :public_body_name => "Apostrophe's")
      expect(
        described_class.change_request_message(change_request, true).subject
      ).to eq("Add authority - Apostrophe's")
    end
  end
end

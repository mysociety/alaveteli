# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::AccountMailer do

  describe '#account_request' do
    let(:account_request) do
      AlaveteliPro::AccountRequest.new(email: 'test@localhost',
                                       reason: 'Have a look around',
                                       marketing_emails: 'no',
                                       training_emails: 'yes',
                                       offer_code: 'SPECIAL')
    end

      before do
        AlaveteliPro::AccountMailer.account_request(account_request)
        @mail = ActionMailer::Base.deliveries[0]
      end

    it "sends the email to the pro contact address" do
      expect(@mail.to).to eq [AlaveteliConfiguration.pro_contact_email]
    end

    it 'sends the email from the blackhole email address' do
      expect(@mail.from).to eq ["#{AlaveteliConfiguration::blackhole_prefix}@#{AlaveteliConfiguration::incoming_email_domain}"]
    end

    it 'has a subject including "account request"' do
      expect(@mail.subject).to match("account request")
    end

    it 'includes the email address' do
      expect(@mail.body).to match(account_request.email)
    end

    it 'includes the reason' do
      expect(@mail.body).to match(account_request.reason)
    end

    it 'includes the offer code' do
      expect(@mail.body).to match(account_request.offer_code)
    end

    it 'includes the marketing emails opt-in' do
      expect(@mail.body).to match("Marketing emails opt-in: #{account_request.marketing_emails}")
    end

    it 'includes the training emails opt-in' do
      expect(@mail.body).to match("Training emails opt-in: #{account_request.training_emails}")
    end
  end

end

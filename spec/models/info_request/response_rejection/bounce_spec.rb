# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::ResponseRejection::Bounce do

  it 'inherits from Base' do
    expect(described_class.superclass).
      to eq(InfoRequest::ResponseRejection::Base)
  end

  describe '#reject' do

    it 'does nothing and returns true if the mail has no From address' do
      raw_email = <<-EOF.strip_heredoc
      To: Requester <request-333-xxx@example.com>
      Subject: No From header
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      args = [double('info_request'), email, double('raw_email_data')]

      expect(described_class.new(*args).reject).to eq(true)
    end

    it 'does nothing and returns true if the info_request is external' do
      info_request = object_double(InfoRequest.new, :is_external? => true)
      raw_email = <<-EOF.strip_heredoc
      From: sender@example.com
      To: Requester <request-333-xxx@example.com>
      Subject: External
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      args = [info_request, email, double('raw_email_data')]

      expect(described_class.new(*args).reject).to eq(true)
    end

    it 'bounces the email' do
      info_request = FactoryGirl.create(:info_request)
      raw_email = <<-EOF.strip_heredoc
      From: sender@example.com
      To: Requester <request-333-xxx@example.com>
      Subject: External
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      args = [info_request, email, raw_email]

      described_class.new(*args).reject

      expect(ActionMailer::Base.deliveries.first.to).
        to eq(['sender@example.com'])

      ActionMailer::Base.deliveries.clear
    end

  end

end

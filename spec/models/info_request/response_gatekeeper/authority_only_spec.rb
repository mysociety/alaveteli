# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::ResponseGatekeeper::AuthorityOnly do

  it 'inherits from Base' do
    expect(described_class.superclass).
      to eq(InfoRequest::ResponseGatekeeper::Base)
  end


  describe '#allow?' do

    it 'requires an email' do
      gatekeeper = described_class.new(FactoryGirl.build(:info_request))
      expect{ gatekeeper.allow? }.to raise_error(ArgumentError)
    end

    context 'if the email has no From address' do

      it 'does not allow the email' do
        raw = <<-EOF.strip_heredoc
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))

        expect(gatekeeper.allow?(email)).to eq(false)
      end

      it 'sets a reason' do
        raw = <<-EOF.strip_heredoc
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        reason = 'Only the authority can reply to this request, but there is ' \
                 'no "From" address to check against'
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))
        gatekeeper.allow?(email)
        expect(gatekeeper.reason).to eq(reason)
      end

    end

    context 'if the email is not from the authority' do

      it 'does not allow the email' do
        raw = <<-EOF.strip_heredoc
        From: spam@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))

        expect(gatekeeper.allow?(email)).to eq(false)
      end

      it 'sets a reason' do
        raw = <<-EOF.strip_heredoc
        From: spam@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        reason = "Only the authority can reply to this request, and I don't " \
                 "recognise the address this reply was sent from"
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))
        gatekeeper.allow?(email)
        expect(gatekeeper.reason).to eq(reason)
      end

    end

    context 'if the email is from the authority' do

      it 'allows the email' do
        raw = <<-EOF.strip_heredoc
        From: authority@example.com
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))

        expect(gatekeeper.allow?(email)).to eq(true)
      end

      it 'sets the reason to nil' do
        raw = <<-EOF.strip_heredoc
        From: authority@example.com
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        gatekeeper = described_class.new(FactoryGirl.build(:info_request))
        gatekeeper.allow?(email)

        expect(gatekeeper.reason).to be_nil
      end

    end

    context 'if the request already has a reply from a given domain' do

      it 'allows the email' do
        raw = <<-EOF.strip_heredoc
        From: someone@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        info_request = FactoryGirl.create(:info_request)
        info_request.receive(email, raw)

        gatekeeper = described_class.new(info_request)

        expect(gatekeeper.allow?(email)).to eq(true)
      end


      it 'sets the reason to nil' do
        raw = <<-EOF.strip_heredoc
        From: someone@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        email = MailHandler.mail_from_raw_email(raw)
        info_request = FactoryGirl.create(:info_request)
        info_request.receive(email, raw)

        gatekeeper = described_class.new(info_request)

        expect(gatekeeper.reason).to be_nil
      end

    end

  end

end

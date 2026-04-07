require 'spec_helper'

RSpec.describe InfoRequest::ResponseGatekeeper::AuthorityOnly do
  it 'inherits from Base' do
    expect(described_class.superclass).
      to eq(InfoRequest::ResponseGatekeeper::Base)
  end

  describe '#allow?' do
    it 'requires a mail' do
      gatekeeper = described_class.new(FactoryBot.build(:info_request))
      expect { gatekeeper.allow? }.to raise_error(ArgumentError)
    end

    context 'if the mail has no From address' do
      it 'does not allow the mail' do
        inbound_email = <<-EOF.strip_heredoc
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        gatekeeper = described_class.new(FactoryBot.build(:info_request))

        expect(gatekeeper.allow?(mail)).to eq(false)
      end

      it 'sets a reason' do
        inbound_email = <<-EOF.strip_heredoc
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        reason = 'Only the authority can reply to this request, but there is ' \
                 'no "From" address to check against'
        gatekeeper = described_class.new(FactoryBot.build(:info_request))
        gatekeeper.allow?(mail)
        expect(gatekeeper.reason).to eq(reason)
      end
    end

    context 'if the mail is not from the authority' do
      it 'does not allow the mail' do
        inbound_email = <<-EOF.strip_heredoc
        From: spam@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        gatekeeper = described_class.new(FactoryBot.build(:info_request))

        expect(gatekeeper.allow?(mail)).to eq(false)
      end

      it 'sets a reason' do
        inbound_email = <<-EOF.strip_heredoc
        From: spam@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        reason = "Only the authority can reply to this request, and I don't " \
                 "recognise the address this reply was sent from"
        gatekeeper = described_class.new(FactoryBot.build(:info_request))
        gatekeeper.allow?(mail)
        expect(gatekeeper.reason).to eq(reason)
      end
    end

    context 'if the mail is from the authority' do
      it 'allows the mail' do
        inbound_email = <<-EOF.strip_heredoc
        From: authority@example.com
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        gatekeeper = described_class.new(FactoryBot.build(:info_request))

        expect(gatekeeper.allow?(mail)).to eq(true)
      end

      it 'sets the reason to nil' do
        inbound_email = <<-EOF.strip_heredoc
        From: authority@example.com
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        gatekeeper = described_class.new(FactoryBot.build(:info_request))
        gatekeeper.allow?(mail)

        expect(gatekeeper.reason).to be_nil
      end
    end

    context 'if the request already has a reply from a given domain' do
      it 'allows the mail' do
        inbound_email = <<-EOF.strip_heredoc
        From: someone@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        info_request = FactoryBot.create(:info_request)
        info_request.receive(mail)

        gatekeeper = described_class.new(info_request)

        expect(gatekeeper.allow?(mail)).to eq(true)
      end

      it 'sets the reason to nil' do
        inbound_email = <<-EOF.strip_heredoc
        From: someone@example.org
        To: request-123@example.com
        Subject: Basic Email
        Hello, World
        EOF
        mail = Mail.from_source(inbound_email)
        info_request = FactoryBot.create(:info_request)
        info_request.receive(mail)

        gatekeeper = described_class.new(info_request)

        expect(gatekeeper.reason).to be_nil
      end
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe InfoRequest::ResponseGatekeeper::SpamChecker do

  describe '.new' do

    it 'sets a default spam_action' do
      default = AlaveteliConfiguration.incoming_email_spam_action
      expect(described_class.new.spam_action).to eq(default)
    end

    it 'allows a custom spam_action' do
      expect(described_class.new(:spam_action => 'x').spam_action).to eq('x')
    end

    it 'sets a default spam_header' do
      default = AlaveteliConfiguration.incoming_email_spam_header
      expect(described_class.new.spam_header).to eq(default)
    end

    it 'allows a custom spam_header' do
      expect(described_class.new(:spam_header => 'x').spam_header).to eq('x')
    end

    it 'sets a default spam_threshold' do
      default = AlaveteliConfiguration.incoming_email_spam_threshold
      expect(described_class.new.spam_threshold).to eq(default)
    end

    it 'allows a custom spam_threshold' do
      expect(described_class.new(:spam_threshold => 'x').spam_threshold).
        to eq('x')
    end

  end

  describe '#spam_action' do

    it 'returns the spam_action' do
      expect(described_class.new(:spam_action => 'x').spam_action).to eq('x')
    end

  end

  describe '#rejection_action' do

    it 'is an alias for #spam_action' do
      gatekeeper = described_class.new
      expect(gatekeeper.rejection_action).to eq(gatekeeper.spam_action)
    end

  end

  describe '#spam_header' do

    it 'returns the spam_header' do
      expect(described_class.new(:spam_header => 'x').spam_header).to eq('x')
    end

  end

  describe '#spam_threshold' do

    it 'returns the spam_threshold' do
      expect(described_class.new(:spam_threshold => 'x').spam_threshold).
        to eq('x')
    end

  end

  describe '#allow?' do

    it 'allows a mail if the spam checker is not configured' do
      spam_email = <<-EOF.strip_heredoc
      From: spam@example.org
      To: FOI Person <authority@example.com>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000
      Plz buy my spam
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      attrs = { :spam_header => nil,
                :spam_threshold => 100 }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.allow?(email)).to eq(true)
    end

    it 'allows a mail if the mail is not spam' do
      raw_email = <<-EOF.strip_heredoc
      From: person@example.org
      To: FOI Person <authority@example.com>
      Subject: Not spam
      X-Spam-Score: 10
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      attrs = { :spam_header => 'X-Spam-Score',
                :spam_threshold => 100,
                :spam_action => 'discard' }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.allow?(email)).to eq(true)
    end

    it 'does not allow spam' do
      spam_email = <<-EOF.strip_heredoc
      From: spammer@example.org
      To: FOI Person <authority@example.com>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000
      Plz buy my spam
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      attrs = { :spam_header => 'X-Spam-Score',
                :spam_threshold => 100,
                :spam_action => 'discard' }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.allow?(email)).to eq(false)
    end
  end

  describe '#reason' do

    it 'returns the reason that the email was rejected' do
      gatekeeper = described_class.new(:spam_threshold => 10.0)
      message = 'Incoming message has a spam score above the configured ' \
                'threshold (10.0).'
      expect(gatekeeper.reason).to eq(message)
    end

  end

  describe '#spam?' do

    it 'is spam if the email has a spam score above the spam threshold' do
      spam_email = <<-EOF.strip_heredoc
      From: spammer@example.org
      To: FOI Person <authority@example.com>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000.4
      Plz buy my spam
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      attrs = { :spam_header => 'X-Spam-Score',
                :spam_threshold => 100 }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.spam?(email)).to eq(true)
    end

    it 'is not spam if the spam score is below the spam threshold' do
      spam_email = <<-EOF.strip_heredoc
      From: person@example.org
      To: FOI Person <authority@example.com>
      Subject: Not spam
      X-Spam-Score: 10
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      attrs = { :spam_header => 'X-Spam-Score',
                :spam_threshold => 100 }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.spam?(email)).to eq(false)
    end

    it 'is not spam if the email does not have a spam header' do
      spam_email = <<-EOF.strip_heredoc
      From: person@example.org
      To: FOI Person <authority@example.com>
      Subject: Not spam
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      attrs = { :spam_header => 'X-Spam-Score',
                :spam_threshold => 100 }
      gatekeeper = described_class.new(attrs)
      expect(gatekeeper.spam?(email)).to eq(false)
    end

  end

  describe '#spam_score' do

    it 'returns the spam score of an email' do
      spam_email = <<-EOF.strip_heredoc
      From: spammer@example.org
      To: FOI Person <authority@example.com>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000.4
      Plz buy my spam
      EOF
      email = MailHandler.mail_from_raw_email(spam_email)
      gatekeeper = described_class.new(:spam_header => 'X-Spam-Score')
      expect(gatekeeper.spam_score(email)).to eq(1000.4)
    end

    it 'returns 0.0 if the mail does not have the spam header' do
      raw_email = <<-EOF.strip_heredoc
      From: from@example.org
      To: FOI Person <authority@example.com>
      Subject: No spam header
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      gatekeeper = described_class.new
      expect(gatekeeper.spam_score(email)).to eq(0.0)
    end

  end

  describe '#configured?' do

    it 'requires a spam_action to be configured' do
      gatekeeper = described_class.new(:spam_action => nil)
      expect(gatekeeper).to_not be_configured
    end

    it 'requires a spam_header to be configured' do
      gatekeeper = described_class.new(:spam_header => nil)
      expect(gatekeeper).to_not be_configured
    end

    it 'requires a spam_threshold to be configured' do
      gatekeeper = described_class.new(:spam_threshold => nil)
      expect(gatekeeper).to_not be_configured
    end

    it 'is configured if a spam_action, spam_header and spam_threshold exist' do
      attrs = { :spam_action => 'discard',
                :spam_header => 'X-Spam-Score',
                :spam_threshold => 10.0 }
      expect(described_class.new(attrs)).to be_configured
    end

  end

end

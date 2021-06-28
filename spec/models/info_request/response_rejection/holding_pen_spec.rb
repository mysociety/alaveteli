require 'spec_helper'

describe InfoRequest::ResponseRejection::HoldingPen do

  it 'inherits from Base' do
    expect(described_class.superclass).
      to eq(InfoRequest::ResponseRejection::Base)
  end

  describe '.new' do

    it 'finds and sets the holding_pen' do
      rejection = described_class.new(double, double, double)
      expect(rejection.holding_pen).to be_holding_pen_request
    end

  end

  describe '.reject' do

    it 'returns false if the info_request is the holding_pen' do
      holding_pen = InfoRequest.holding_pen_request
      rejection = described_class.new(holding_pen, double, double)
      expect(rejection.reject).to eq(false)
    end

    it 'redirects the mail to the holding pen' do
      info_request = FactoryBot.create(:info_request)
      raw_email = <<-EOF.strip_heredoc
      From: sender@example.com
      To: FOI Person <authority@example.com>
      Subject: External
      Hello, World
      EOF
      email = MailHandler.mail_from_raw_email(raw_email)
      args = [info_request, email, raw_email]

      described_class.new(*args).reject

      expect(InfoRequest.holding_pen_request.incoming_messages.count).to eq(1)
    end

  end

end

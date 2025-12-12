require 'spec_helper'

RSpec.describe InfoRequest::ResponseRejection::Base do
  describe '.new' do
    it 'requires an info_request' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'requires a mail' do
      expect { described_class.new(double('info_request')) }.
        to raise_error(ArgumentError)
    end

    it 'requires an inbound_email' do
      expect { described_class.new(double('info_request'), double('mail')) }.
        to raise_error(ArgumentError)
    end

    it 'assigns the info_request' do
      info_request = FactoryBot.build(:info_request)
      args = [info_request, double('mail'), double('inbound_email')]
      rejection = described_class.new(*args)
      expect(rejection.info_request).to eq(info_request)
    end

    it 'assigns the mail' do
      info_request = FactoryBot.build(:info_request)
      mail = double('mail')
      args = [info_request, mail, double('inbound_email')]
      rejection = described_class.new(*args)
      expect(rejection.mail).to eq(mail)
    end

    it 'assigns the inbound_email' do
      info_request = FactoryBot.build(:info_request)
      inbound_email = double('inbound_email')
      args = [info_request, double('mail'), inbound_email]
      rejection = described_class.new(*args)
      expect(rejection.inbound_email).to eq(inbound_email)
    end
  end

  describe '#reject' do
    it 'returns true' do
      args = [double('info_request'), double('mail'), double('inbound_email')]
      rejection = described_class.new(*args)
      expect(rejection.reject).to eq(true)
    end

    it 'accepts a rejection reason' do
      args = [double('info_request'), double('mail'), double('inbound_email')]
      rejection = described_class.new(*args)
      expect(rejection.reject('')).to eq(true)
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MailServerLog::DeliveryStatusSerializer do

  describe '.dump' do

    it 'returns a String representation of the Exim status' do
      status = MailServerLog::EximDeliveryStatus.new(:message_arrival)
      result = MailServerLog::DeliveryStatusSerializer.dump(status)
      expect(result).to eq 'message_arrival'
    end

    it 'returns a delivery status for the Postfix status' do
      status = MailServerLog::PostfixDeliveryStatus.new(:sent)
      result = MailServerLog::DeliveryStatusSerializer.dump(status)
      expect(result).to eq 'sent'
    end

  end

  describe '.load' do

    context 'using the :exim MTA' do

      it 'returns an EximDeliveryStatus object' do
        status = MailServerLog::EximDeliveryStatus.new(:message_arrival)
        result = MailServerLog::DeliveryStatusSerializer.load('message_arrival')
        expect(result).to eq status
      end

    end

    context 'using the :postfix MTA' do

      before do
        allow(AlaveteliConfiguration).to receive(:mta_log_type).
          and_return('postfix')
      end

      it 'returns a PostfixDeliveryStatus object' do
        status = MailServerLog::PostfixDeliveryStatus.new(:sent)
        result = MailServerLog::DeliveryStatusSerializer.load('sent')
        expect(result).to eq status
      end

    end

    it 'raises an error if passed an invalid status string' do
      expect { MailServerLog::DeliveryStatusSerializer.load('whut') }.
        to raise_error(ArgumentError, "Invalid MTA status: whut")
    end

    it 'raises an error if it detects an unfamiliar MTA type' do
      allow(AlaveteliConfiguration).to receive(:mta_log_type).
        and_return('imaginary')

      expect { MailServerLog::DeliveryStatusSerializer.load('sent') }.
        to raise_error(RuntimeError, "Unexpected MTA type: imaginary")
    end

  end

end

require 'spec_helper'

describe MailServerLog::DeliveryStatusSerializer do

  describe '.dump' do

    it 'returns a String representation of the delivery status' do
      status = MailServerLog::DeliveryStatus.new(:delivered)
      result = MailServerLog::DeliveryStatusSerializer.dump(status)
      expect(result).to eq 'delivered'
    end

  end

  describe '.load' do

    it 'returns a DeliveryStatus' do
      status = MailServerLog::DeliveryStatus.new(:sent)
      result = MailServerLog::DeliveryStatusSerializer.load('sent')
      expect(result).to eq status
    end

    it 'raises an error if passed an invalid status string' do
      expect { MailServerLog::DeliveryStatusSerializer.load('whut') }.
        to raise_error(ArgumentError, "Invalid delivery status: whut")
    end

  end

end

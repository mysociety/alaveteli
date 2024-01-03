require 'spec_helper'

RSpec.describe FoiAttachment::DeliveryStatusNotification do
  let(:valid_status_body) do
    <<~EOF
    Action: failed
    Status: 5.4.1
    EOF
  end

  let(:invalid_status_body) do
    <<~EOF
    Action: failed
    Status: invalid
    EOF
  end

  describe '#status' do
    subject { dsn.status }
    let(:dsn) { described_class.new(body) }

    context 'with a valid status' do
      let(:body) { valid_status_body }
      it { is_expected.to eq('5.4.1') }
    end

    context 'with an invalid status' do
      let(:body) { invalid_status_body }
      it { is_expected.to be_nil }
    end
  end

  describe '#message' do
    subject { dsn.message }
    let(:dsn) { described_class.new(body) }

    context 'with a valid status' do
      let(:body) { valid_status_body }
      it { is_expected.to eq('No answer from host') }
    end

    context 'with an invalid status' do
      let(:body) { invalid_status_body }
      it { is_expected.to be_nil }
    end
  end
end

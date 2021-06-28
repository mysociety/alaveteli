require 'spec_helper'

RSpec.describe AdminRequestsHelper do
  include AdminRequestsHelper

  describe '#hidden_user_explanation' do
    subject do
      hidden_user_explanation(label: label, message: message, state: state)
    end

    context 'with valid arguments' do
      let(:label) { 'A vexatious request' }
      let(:state) { 'vexatious' }
      let(:message) { 'vexatious' }

      it { is_expected.to match(/label class="radio inline"/) }
      it { is_expected.to match(/A vexatious request/) }
      it { is_expected.to match(/type="radio"/) }
      it { is_expected.to match(/name="reason"/) }
      it { is_expected.to match(/id="reason_vexatious_vexatious"/) }
      it { is_expected.to match(/value="vexatious"/) }
      it { is_expected.to match(/data-message="vexatious"/) }
    end

    context 'with an invalid state' do
      let(:label) { double }
      let(:state) { 'invalid' }
      let(:message) { double }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end
end

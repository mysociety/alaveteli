require 'spec_helper'

describe User::EmailAlerts do
  let(:user) { FactoryBot.create(:user, receive_email_alerts: true) }

  describe '.disable_by_token' do
    subject { described_class.disable_by_token(token) }

    context 'with a valid token' do
      let(:token) { described_class.token(user) }

      it 'disables email alerts for the user' do
        expect { subject }.
          to change { user.reload.receive_email_alerts }.from(true).to(false)
      end
    end

    context 'with an invalid token' do
      let(:token) { 'invalid' }
      it { is_expected.to be_falsey }
    end

    context 'when the user no longer exists' do
      let(:token) { described_class.token(user) }
      before { user.destroy! }
      it { is_expected.to be_falsey }
    end
  end

  describe '.token' do
    subject { described_class.token(user) }
    it { is_expected.to eq(described_class.verifier.generate(user.id)) }
  end

  describe '.verifier' do
    subject { described_class.verifier }
    it { is_expected.to be_a(ActiveSupport::MessageVerifier) }
  end

  describe '#disable' do
    subject { described_class.new(user).disable }

    it 'disables email alerts for the user' do
      expect { subject }.
        to change { user.receive_email_alerts }.from(true).to(false)
    end

    it 'is idempotent' do
      subject
      expect { subject }.not_to change { user.receive_email_alerts }
    end
  end
end

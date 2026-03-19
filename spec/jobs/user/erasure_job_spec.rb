require 'spec_helper'

RSpec.describe User::ErasureJob, type: :job do
  let(:user) { FactoryBot.create(:user, :closed) }
  let(:editor) { instance_double(User) }
  let(:reason) { 'GDPR' }

  describe '#perform' do
    subject do
      described_class.new.perform(user, editor: editor, reason: reason)
    end

    it 'calls erase! on the user with the given editor and reason' do
      expect(user).to receive(:erase!).with(editor: editor, reason: reason)
      subject
    end

    context 'when the user has unmasked attachments' do
      let(:info_request) { FactoryBot.create(:info_request, user: user) }

      let(:message) do
        FactoryBot.create(
          :incoming_message,
          :with_pdf_attachment,
          info_request: info_request
        )
      end

      let!(:attachment) do
        _attachment = message.get_attachments_for_display.first
        _attachment.update_column(:masked_at, nil)
        _attachment
      end

      it 'masks unmasked attachments' do
        expect { subject }.to change { attachment.reload.masked_at }.from(nil)
      end
    end
  end
end

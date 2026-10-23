require 'spec_helper'

RSpec.describe User::ErasureJob, type: :job do
  let(:user) { FactoryBot.build(:user, :closed) }
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
  end
end

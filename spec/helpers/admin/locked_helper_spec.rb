require 'spec_helper'

RSpec.describe Admin::LockedHelper do
  describe '#locked_icon' do
    subject { helper.locked_icon(resource) }

    context 'the resource is unsupported' do
      let(:resource) { User.new }

      it 'raises an NoMethodError' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context 'with an locked IncomingMessage' do
      let(:resource) { FactoryBot.create(:incoming_message) }
      before { allow(resource).to receive(:locked?).and_return(true) }
      it { is_expected.to include('icon-foi-attachment--locked') }
    end

    context 'with an unlocked IncomingMessage' do
      let(:resource) { FactoryBot.create(:incoming_message) }
      it { is_expected.to be_nil }
    end

    context 'with an locked FoiAttachment' do
      let(:resource) { FactoryBot.create(:body_text, locked: true) }
      it { is_expected.to include('icon-foi-attachment--locked') }
    end

    context 'with an unlocked FoiAttachment' do
      let(:resource) { FactoryBot.create(:body_text, locked: false) }
      it { is_expected.to be_nil }
    end
  end
end

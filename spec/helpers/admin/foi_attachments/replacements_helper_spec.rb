require 'spec_helper'

RSpec.describe Admin::FoiAttachments::ReplacementsHelper do
  describe '#clear_replacement_button' do
    subject { helper.clear_replacement_button(foi_attachment) }

    let(:foi_attachment) do
      double(
        replaced?: replaced,
        retained?: retained,
        replacement_clearable?: replacement_clearable
      )
    end

    context 'when the replacement is clearable' do
      let(:replaced) { true }
      let(:retained) { true }
      let(:replacement_clearable) { true }

      it { is_expected.to include('Clear replacement') }
      it { is_expected.to include('btn btn-danger') }
      it { is_expected.to include('name="_method"') }
      it { is_expected.to include('value="delete"') }
      it { is_expected.to include('revert to the original') }
      it { is_expected.not_to include('disabled') }
    end

    context 'when the attachment has no replacement' do
      let(:replaced) { false }
      let(:retained) { true }
      let(:replacement_clearable) { false }

      it { is_expected.to include('disabled') }
      it { is_expected.to include('No replacement to clear.') }
    end

    context 'when the attachment is replaced and retained' do
      let(:replaced) { true }
      let(:retained) { false }
      let(:replacement_clearable) { false }

      it { is_expected.to include('disabled') }
      it { is_expected.to include('raw email has been erased') }
    end
  end
end

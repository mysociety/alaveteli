require 'spec_helper'

RSpec.describe Admin::FoiAttachments::ReplacementsHelper do
  describe '#clear_replacement_button' do
    subject { helper.clear_replacement_button(foi_attachment) }

    let(:foi_attachment) do
      double(
        replaced?: replaced,
        erased?: erased,
        replacement_clearable?: replacement_clearable
      )
    end

    context 'when the replacement is clearable' do
      let(:replaced) { true }
      let(:erased) { false }
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
      let(:erased) { false }
      let(:replacement_clearable) { false }

      it { is_expected.to include('disabled') }
      it { is_expected.to include('No replacement to clear.') }
    end

    context 'when the attachment is replaced and the raw email is erased' do
      let(:replaced) { true }
      let(:erased) { true }
      let(:replacement_clearable) { false }

      it { is_expected.to include('disabled') }
      it { is_expected.to include('raw email has been erased') }
    end
  end
end

require 'spec_helper'

RSpec.describe Admin::ToDoListHelper, type: :helper do
  include Admin::ToDoListHelper

  describe '#todo_list_label' do
    subject { todo_list_label_style(id) }

    context 'when the id is important' do
      let(:id) { described_class::PRIORITY_IMPORTANT.first }
      it { is_expected.to eq('label-important') }
    end

    context 'when the id is warning' do
      let(:id) { described_class::PRIORITY_WARNING.first }
      it { is_expected.to eq('label-warning') }
    end

    context 'when the id is info' do
      let(:id) { described_class::PRIORITY_INFO.first }
      it { is_expected.to eq('label-info') }
    end

    context 'when the id is none' do
      let(:id) { described_class::PRIORITY_NONE.first }
      it { is_expected.to eq('') }
    end

    context 'when the id is not a set priority' do
      let(:id) { 'foo' }
      it { is_expected.to eq('label-important') }
    end
  end
end

require 'spec_helper'

RSpec.describe Redactable::Unredacted do
  let(:record) do
    klass = Class.new do
      include Redactable
      redactable :title

      def title = 'Some title'
      def safe = 'Some generic content'
    end

    klass.new
  end

  subject { described_class.new(record) }

  it 'responds to all methods on the given record' do
    is_expected.to respond_to(:title)
    is_expected.to respond_to(:safe)
  end

  it 'does not define methods for undeclared attributes' do
    is_expected.not_to respond_to(:name)
  end

  it 'grants unredacted access when reading redactable attributes' do
    expect(subject).to receive(:with_unredacted_access).and_call_original
    expect(subject.title).to eq('Some title')
  end

  it 'does not grant unredacted access for non-redactable attributes' do
    expect(subject).not_to receive(:with_unredacted_access)
    expect(subject.safe).to eq('Some generic content')
  end
end

require 'spec_helper'

RSpec.describe Redactable::Redacted do
  let(:record) do
    klass = Class.new do
      include Redactable
      redactable :title

      def title = 'Some title'
      def safe = 'Some generic content'
    end

    klass.new
  end

  before do
    allow(record).
      to receive(:info_request).
      and_return(double(apply_masks: '[REDACTED] title'))
  end

  subject { described_class.new(record) }

  it 'responds to all methods on the given record' do
    is_expected.to respond_to(:title)
    is_expected.to respond_to(:safe)
  end

  it 'does not define methods for undeclared attributes' do
    is_expected.not_to respond_to(:name)
  end

  it 'applies redactions to redactable attributes' do
    expect(subject.title).to eq('[REDACTED] title')
  end

  it 'does not apply redactions to non-redactable attributes' do
    expect(record).not_to receive(:apply_masks)
    expect(subject.safe).to eq('Some generic content')
  end
end

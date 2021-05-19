RSpec.shared_examples 'concerns/info_request/draft_title_validation' do |record|
  subject { record }

  before { record.title = title }

  context 'without a title' do
    let(:title) { nil }
    it { is_expected.to be_valid }
  end

  context 'with an empty title' do
    let(:title) { '' }
    it { is_expected.to be_valid }
  end

  context 'with any title' do
    let(:title) { 'A' }
    it { is_expected.to be_valid }
  end

  context 'with a title over 200 characters' do
    let(:title) { 'x' * 201 }
    it { is_expected.not_to be_valid }
  end
end

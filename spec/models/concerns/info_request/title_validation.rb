RSpec.shared_examples 'concerns/info_request/title_validation' do |record|
  subject { record }

  before do
    record.title = title
    record.valid?
  end

  context 'with a title containing all ASCII characters' do
    let(:title) { 'Abcde' }
    it { is_expected.to be_valid }
  end

  context 'with a title containing unicode characters' do
    let(:title) { 'Кажете' }
    it { is_expected.to be_valid }
  end

  context 'with a title containing numbers and lower case' do
    let(:title) { '999 calls' }
    it { is_expected.to be_valid }
  end

  context 'with a title containing only an upper case single word' do
    let(:title) { 'HMRC' }
    it { is_expected.to be_valid }
  end

  context 'without a title' do
    let(:title) { nil }

    it { is_expected.not_to be_valid }

    it do
      expect(subject.errors[:title]).
        to include('Please enter a summary of your request')
    end
  end

  context 'with an empty title' do
    let(:title) { '' }

    it { is_expected.not_to be_valid }

    it do
      expect(subject.errors[:title]).
        to include('Please enter a summary of your request')
    end
  end

  context 'with a title containing no ASCII or unicode characters' do
    let(:title) { '55555' }

    it { is_expected.not_to be_valid }

    it do
      expect(subject.errors[:title]).
        to include('Please write a summary with some text in it')
    end
  end

  context 'with a title over 200 characters' do
    let(:title) { 'Lorem ipsum ' * 17 }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Please keep the summary short, like in the subject of an ' \
            'email. You can use a phrase, rather than a full sentence.'
      expect(subject.errors[:title]).to include(msg)
    end
  end

  context 'with a title less than 3 chars long' do
    let(:title) { 'Re' }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Summary is too short. Please be a little more ' \
            'descriptive about the information you are asking for.'
      expect(subject.errors[:title]).to include(msg)
    end
  end

  context 'with a title that just says "FOI requests"' do
    let(:title) { 'FOI requests' }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Please describe more what the request is about in the ' \
            'subject. There is no need to say it is an FOI request, ' \
            'we add that on anyway.'
      expect(subject.errors[:title]).to include(msg)
    end
  end

  context 'with a title that just says "Freedom of Information request"' do
    let(:title) { 'Freedom of Information request' }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Please describe more what the request is about in the ' \
            'subject. There is no need to say it is an FOI request, ' \
            'we add that on anyway.'
      expect(subject.errors[:title]).to include(msg)
    end
  end

  context 'with a title which is not a mix of upper and lower case' do
    let(:title) { 'lorem lipsum' }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Please write the summary using a mixture of capital and ' \
            'lower case letters. This makes it easier for others to read.'
      expect(subject.errors[:title]).to include(msg)
    end
  end

  context 'with a short all lowercase title' do
    let(:title) { 'test' }

    it { is_expected.not_to be_valid }

    it do
      msg = 'Please write the summary using a mixture of capital and ' \
            'lower case letters. This makes it easier for others to read.'
      expect(subject.errors[:title]).to include(msg)
    end
  end
end

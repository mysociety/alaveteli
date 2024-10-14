RSpec.shared_examples 'concerns/notable_and_taggable' do |factory_opts|
  let(:record) { FactoryBot.build(*factory_opts) }

  describe '#all_notes' do
    subject { record.all_notes }

    before { record.tag_string = 'foo:1' }

    let!(:tagged_note) { FactoryBot.create(:note, notable_tag: 'foo') }
    let!(:other_tagged_note) { FactoryBot.create(:note, notable_tag: 'bar') }
    let!(:tagged_note_with_value) do
      FactoryBot.create(:note, notable_tag: 'foo:1')
    end
    let!(:tagged_note_with_other_value) do
      FactoryBot.create(:note, notable_tag: 'foo:2')
    end

    it { is_expected.to include tagged_note }
    it { is_expected.to include tagged_note_with_value }
    it { is_expected.to_not include other_tagged_note }
    it { is_expected.to_not include tagged_note_with_other_value }
  end
end

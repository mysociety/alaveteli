RSpec.shared_examples 'concerns/notable' do |*factory_opts|
  let(:record) { FactoryBot.build(*factory_opts) }

  describe '#all_notes' do
    subject { record.all_notes }

    let!(:note) { FactoryBot.create(:note, notable: record) }
    let!(:other_note) { FactoryBot.create(:note) }

    it { is_expected.to include note }
    it { is_expected.to_not include other_note }
  end
end

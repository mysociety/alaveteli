RSpec.shared_examples 'concerns/taggable_terms' do |*factory_opts, attr_under_test|
  let(:record) { FactoryBot.build(*factory_opts) }

  let(:terms_tags) do
    { /train/i => 'trains',
      /bus/i => 'bus',
      /locomotive/i => 'trains',
      /bike/ => 'bicycles' }
  end

  before do
    record.taggable_terms = { attr_under_test => terms_tags }
  end

  describe '#update_taggable_terms' do
    subject { record.update_taggable_terms }
    before { subject }

    it 'applies a tag when a term matches' do
      expect(record).to be_tagged('bus')
    end

    it 'does not apply a tag when there is no match for a term' do
      expect(record).not_to be_tagged('bicycles')
    end

    it 'applies a tag when one term term matches but a later term with the same tag does not' do
      # i.e. keep "trains" because it matched /train/, so don't remove it
      # because it didn't match /locomotive/
      expect(record).to be_tagged('trains')
    end
  end
end

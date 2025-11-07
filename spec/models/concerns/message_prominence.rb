RSpec.shared_examples 'concerns/message_prominence' do |*factory_opts|
  let(:record) { FactoryBot.build(*factory_opts) }

  describe 'when validating' do
    it 'should be valid with valid prominence values' do
      %w[hidden requester_only normal].each do |prominence|
        record.prominence = prominence
        expect(record.valid?).to be true
      end
    end

    it 'should not be valid with an invalid prominence value' do
      record.prominence = 'invalid'
      expect(record.valid?).to be false
    end
  end

  describe 'when asked if it is indexed by search' do
    subject { record.indexed_by_search? }

    it 'should return false if it has prominence "hidden"' do
      record.prominence = 'hidden'
      is_expected.to be false
    end

    it 'should return false if it has prominence "requester_only"' do
      record.prominence = 'requester_only'
      is_expected.to be false
    end

    it 'should return true if it has prominence "normal"' do
      record.prominence = 'normal'
      is_expected.to be true
    end
  end
end

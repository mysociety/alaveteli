RSpec.shared_examples 'concerns/categorisable' do |factory_opts|
  let(:record) { FactoryBot.create(*factory_opts) }

  describe '.category_root' do
    subject(:root) { described_class.category_root }
    it { is_expected.to be_a(Category) }
    it { expect(root.title).to eq(described_class.to_s) }
  end

  describe '.categories' do
    it 'calls category_root.tree' do
      expect(described_class).to receive_message_chain(:category_root, :tree)
      described_class.categories
    end
  end
end

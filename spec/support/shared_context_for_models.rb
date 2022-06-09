RSpec.shared_context 'base factory', type: :model do
  let(:base_factory) do
    described_class.to_s.underscore.parameterize(separator: '_').to_sym
  end
end

RSpec.shared_examples 'does not deliver any mail' do
  it { is_expected.to be_nil }

  it 'should not deliver any mail' do
    expect { subject }.to_not change { deliveries.size }
  end
end

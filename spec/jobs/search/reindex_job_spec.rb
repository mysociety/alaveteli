require 'spec_helper'

RSpec.describe Search::ReindexJob, type: :job do
  it 'reindexes the record' do
    user = users(:bob_smith_user)
    expect(user).to receive(:reindex)
    described_class.new.perform(user)
  end
end

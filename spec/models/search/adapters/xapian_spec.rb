require 'spec_helper'
require_relative '../shared_examples/backend_contract'

RSpec.describe Search::Adapters::Xapian::Adapter, :xapian do
  subject(:adapter) { described_class.new }
  it_behaves_like 'a search backend'
end

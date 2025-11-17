require 'spec_helper'

RSpec.describe AtiNetworkController do
  describe 'GET showcase' do
    subject { response }

    before { get :showcase }

    it { is_expected.to be_successful }
  end
end

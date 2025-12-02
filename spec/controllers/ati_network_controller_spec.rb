require 'spec_helper'

RSpec.describe AtiNetworkController do
  describe 'GET showcase' do
    context 'when enabled' do
      it 'renders successfully' do
        get :showcase
        expect(response).to be_successful
      end
    end

    context 'when not enabled' do
      around do |example|
        described_class.showcase_enabled = false
        example.run
        described_class.showcase_enabled = true
      end

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :showcase
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

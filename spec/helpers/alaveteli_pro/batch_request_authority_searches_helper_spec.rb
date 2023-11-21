require 'spec_helper'

RSpec.describe AlaveteliPro::BatchRequestAuthoritySearchesHelper do
  include AlaveteliPro::BatchRequestAuthoritySearchesHelper

  describe '#batch_authority_count' do
    subject { batch_authority_count }

    let(:count) { 0 }

    before do
      public_bodies = double(:public_bodies_assoication, count: count)
      @draft_batch_request = double(
        :draft_batch_request, public_bodies: public_bodies
      )
    end

    context 'zero authorities' do
      it 'returns a paragraph with the current count of authorities' do
        is_expected.to include '0 of 500 authorities'
      end
    end

    context 'one authorities' do
      let(:count) { 1 }

      it 'returns a paragraph with the current count of authorities' do
        is_expected.to include '1 of 500 authorities'
      end
    end

    context 'many authorities' do
      let(:count) { 2 }

      it 'returns a paragraph with the current count of authorities' do
        is_expected.to include '2 of 500 authorities'
      end
    end

    it 'includes message template for 0 authorities' do
      is_expected.to include(
        'data-message-template-zero="{{count}} of 500 authorities"'
      )
    end

    it 'includes message template for 1 authority' do
      is_expected.to include(
        'data-message-template-one="{{count}} of 500 authorities"'
      )
    end

    it 'includes message template for many authorities' do
      is_expected.to include(
        'data-message-template-many="{{count}} of 500 authorities"'
      )
    end
  end
end

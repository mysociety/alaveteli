require 'spec_helper'

RSpec.describe InfoRequest::Prominence::EmbargoedNeverQuery do

  describe '#call' do
    subject { described_class.new.call }

    let(:public_request) { FactoryBot.create(:info_request) }
    let(:embargoed_request) { FactoryBot.create(:info_request, :embargoed) }

    let(:embargo_expired_request) do
      # TODO: The :embargo_expired factory doesn't set a set_embargo event.
      # I've manually created it here for now, but this would ideally happen in
      # the factory.
      r = FactoryBot.create(:info_request, :embargoed)
      r.embargo.destroy
      r.log_event('expire_embargo', {})
      r
    end

    it 'includes requests that have never had an embargo' do
      is_expected.to include(public_request)
    end

    it 'excludes requests that have ever had an embargo' do
      is_expected.not_to include(embargoed_request, embargo_expired_request)
    end
  end
end



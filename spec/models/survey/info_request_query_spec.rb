require 'spec_helper'

RSpec.describe Survey::InfoRequestQuery do
  let(:old) { 1.month.ago - 1.day }
  let(:current) { 1.month.ago }
  let(:new) { 1.month.ago + 1.day }

  let!(:old_request) do
    FactoryBot.create(:info_request, created_at: old)
  end

  let!(:normal_request) do
    FactoryBot.create(:info_request, created_at: current)
  end

  let!(:new_request) do
    FactoryBot.create(:info_request, created_at: new)
  end

  let!(:embargoed_request) do
    FactoryBot.create(:embargoed_request, created_at: current)
  end

  let!(:external_request) do
    FactoryBot.create(:external_request, created_at: current)
  end

  let(:user) do
    FactoryBot.build(:user)
  end

  let!(:first_request) do
    FactoryBot.create(:info_request, user: user, created_at: current)
  end

  let!(:second_request) do
    FactoryBot.create(:info_request, user: user, created_at: current + 1.second)
  end

  describe '#call' do
    subject { described_class.new.call }

    it 'returns only results one month old' do
      is_expected.not_to include(old_request)
      is_expected.to include(normal_request)
      is_expected.not_to include(new_request)
    end

    it 'returns embargoed requests' do
      is_expected.to include(embargoed_request)
    end

    it 'does not returns external requests' do
      is_expected.not_to include(external_request)
    end

    it 'returns one request per user' do
      is_expected.to include(first_request)
      is_expected.not_to include(second_request)
    end
  end
end

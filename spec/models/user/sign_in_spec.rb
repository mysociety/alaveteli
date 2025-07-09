# == Schema Information
# Schema version: 20250709114001
#
# Table name: user_sign_ins
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  ip         :inet
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  country    :string
#  user_agent :text
#

require 'spec_helper'

RSpec.describe User::SignIn, type: :model do
  describe 'default_scope' do
    subject { described_class.all }

    context 'sort order is most recent first' do
      let!(:sign_ins) do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
        FactoryBot.create_list(:user_sign_in, 2)
      end

      it { is_expected.to match_array(sign_ins.reverse) }
    end
  end

  describe '.purge' do
    subject { described_class.purge }

    let(:outside_retention_period) do
      travel_to 6.days.ago do
        FactoryBot.create(:user_sign_in)
      end
    end

    let(:inside_retention_period) { FactoryBot.create(:user_sign_in) }

    before do
      allow(AlaveteliConfiguration).
        to receive(:user_sign_in_activity_retention_days).and_return(3)
    end

    it 'purges records outside the retention period' do
      records = described_class.where(id: outside_retention_period.id)
      expect { subject }.to change { records.any? }.from(true).to(false)
    end

    it 'retains records inside the retention period' do
      records = described_class.where(id: inside_retention_period.id)
      expect { subject }.not_to change { records.any? }
    end
  end

  describe '.search' do
    subject { described_class.search(query) }

    before do
      allow(AlaveteliConfiguration).
        to receive(:user_sign_in_activity_retention_days).and_return(1)
    end

    let(:sign_in_1) do
      user = FactoryBot.create(:user, name: 'Alice', email: 'alice@example.com')
      FactoryBot.create(:user_sign_in, ip: '1.1.1.1', user: user)
    end

    let(:sign_in_2) do
      user = FactoryBot.create(:user, name: 'James', email: 'james@example.com')
      FactoryBot.create(:user_sign_in, ip: '2.2.2.2', country: 'XY', user: user)
    end

    let(:sign_in_3) do
      user = FactoryBot.create(:user, name: 'Betty', email: 'betty@example.org')
      ip = '7754:76d4:c7aa:7646:ea68:1abb:4055:4343'
      FactoryBot.create(:user_sign_in, ip: ip, country: 'XX', user: user)
    end

    context 'when given an ip' do
      let(:query) { '1.1.1.1' }
      it { is_expected.to match_array([sign_in_1]) }
    end

    context 'when given an ipv6 ip' do
      let(:query) { '7754:76d4:c7aa:7646:ea68:1abb:4055:4343' }
      it { is_expected.to match_array([sign_in_3]) }
    end

    context 'when given a partial ip' do
      let(:query) { '1.1' }
      it { is_expected.to match_array([sign_in_1]) }
    end

    context 'when given a partial ipv6 ip' do
      let(:query) { '7754:76d4' }
      it { is_expected.to match_array([sign_in_3]) }
    end

    context 'when given a user name' do
      let(:query) { 'Alice' }
      it { is_expected.to match_array([sign_in_1]) }
    end

    context 'when given a user email' do
      let(:query) { 'alice@example.com' }
      it { is_expected.to match_array([sign_in_1]) }
    end

    context 'when given an email domain' do
      let(:query) { 'example.com' }
      it { is_expected.to match_array([sign_in_2, sign_in_1]) }
    end

    context 'when given a country' do
      let(:query) { 'XY' }
      it { is_expected.to match_array([sign_in_2]) }
    end
  end

  describe '#other_users' do
    subject { sign_in.other_users }

    before do
      allow(AlaveteliConfiguration).
        to receive(:user_sign_in_activity_retention_days).and_return(1)
    end

    let(:user_1) { FactoryBot.create(:user) }
    let(:user_2) { FactoryBot.create(:user) }

    let!(:sign_in_1) do
      FactoryBot.create(:user_sign_in, user: user_1, ip: '1.1.1.1')
    end

    let!(:sign_in_2) do
      FactoryBot.create(:user_sign_in, user: user_2, ip: '1.1.1.1')
    end

    let!(:sign_in_3) { FactoryBot.create(:user_sign_in, ip: '2.2.2.2') }

    context 'when there are other users using the same IP' do
      let(:sign_in) { sign_in_1 }
      it { is_expected.to match_array([user_2]) }
    end

    context 'when there are no other users using the same IP' do
      let(:sign_in) { sign_in_3 }
      it { is_expected.to be_empty }
    end
  end

  describe '#save' do
    subject { sign_in.save }

    let(:sign_in) { FactoryBot.build(:user_sign_in) }

    context 'when the retention period is 0' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(0)
      end

      it { is_expected.to eq(false) }
    end

    context 'when the retention period is greater than 0' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#save!' do
    subject { sign_in.save! }

    let(:sign_in) { FactoryBot.build(:user_sign_in) }

    context 'when the retention period is 0' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(0)
      end

      it 'raises RecordNotSaved' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotSaved)
      end
    end

    context 'when the retention period is greater than 0' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:user_sign_in_activity_retention_days).and_return(1)
      end

      it { is_expected.to eq(true) }
    end
  end
end

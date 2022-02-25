# == Schema Information
# Schema version: 20220225094330
#
# Table name: user_sign_ins
#
#  id         :bigint           not null, primary key
#  user_id    :bigint
#  ip         :inet
#  created_at :datetime         not null
#  updated_at :datetime         not null
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

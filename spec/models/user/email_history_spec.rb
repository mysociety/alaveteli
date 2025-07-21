# == Schema Information
# Schema version: 20250717064136
#
# Table name: user_email_histories
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  old_email  :string           not null
#  new_email  :string           not null
#  changed_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'spec_helper'

RSpec.describe User::EmailHistory, type: :model do
  subject(:user_email_history) do
    FactoryBot.build(:user_email_history, user: user)
  end

  let(:user) { FactoryBot.create(:user) }
  let(:old_email) { 'old@example.com' }
  let(:new_email) { 'new@example.com' }

  describe 'associations' do
    it 'belongs to user' do
      expect(user_email_history.user).to be_a(User)
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires user' do
      user_email_history.user = nil
      is_expected.not_to be_valid
    end

    it 'requires old_email' do
      user_email_history.old_email = nil
      is_expected.not_to be_valid
    end

    it 'requires new_email' do
      user_email_history.new_email = nil
      is_expected.not_to be_valid
    end

    it 'requires changed_at' do
      user_email_history.changed_at = nil
      is_expected.not_to be_valid
    end
  end

  describe '.record_change' do
    it 'creates a new email history record' do
      expect {
        user.email_histories.record_change(old_email, new_email)
      }.to change(User::EmailHistory, :count).by(1)
    end

    it 'sets the correct attributes' do
      history = user.email_histories.record_change(old_email, new_email)

      expect(history.user).to eq(user)
      expect(history.old_email).to eq(old_email)
      expect(history.new_email).to eq(new_email)
      expect(history.changed_at).to be_within(1.second).of(Time.current)
    end
  end
end

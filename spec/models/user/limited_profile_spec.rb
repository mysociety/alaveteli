require 'spec_helper'

RSpec.describe User::LimitedProfile do
  it 'module is included to User' do
    expect(User.ancestors).to include(User::LimitedProfile)
  end

  describe '.limited_profile' do
    subject { User.limited_profile }

    let!(:user) { FactoryBot.create(:user) }

    let!(:internal_admin_user) do
      FactoryBot.create(:user, :limited, :internal_admin_user)
    end

    let!(:admin) { FactoryBot.create(:user, :limited, :admin) }
    let!(:pro_admin) { FactoryBot.create(:user, :limited, :pro_admin) }

    let!(:confirmed_user) do
      FactoryBot.create(:user, :limited, confirmed_not_spam: true)
    end

    let!(:user_with_request) do
      FactoryBot.create(:user, :limited, info_requests_count: 1)
    end

    let!(:user_with_classification) do
      FactoryBot.create(:user, :limited, status_update_count: 1)
    end

    let!(:limited_user_1) { FactoryBot.create(:user, :limited) }
    let!(:limited_user_2) { FactoryBot.create(:user, :limited) }

    it { is_expected.to_not include(user) }
    it { is_expected.to_not include(internal_admin_user) }
    it { is_expected.to_not include(admin) }
    it { is_expected.to_not include(pro_admin) }
    it { is_expected.to_not include(confirmed_user) }
    it { is_expected.to_not include(user_with_request) }
    it { is_expected.to_not include(user_with_classification) }
    it { is_expected.to include(limited_user_1) }
    it { is_expected.to include(limited_user_2) }

    it 'returns an ActiveRecord::Relation' do
      is_expected.to be_a(ActiveRecord::Relation)
    end

    it 'is chainable with other scopes' do
      FactoryBot.create(:user, :limited)
      FactoryBot.create(:user, :limited, :banned)

      expect(subject.banned).to have_attributes(count: 1)
    end
  end

  describe 'limited_profile?' do
    subject { user.limited_profile? }

    context 'when limited' do
      let(:user) { FactoryBot.create(:user, :limited) }
      it { is_expected.to eq(true) }
    end

    context 'when the internal_admin_user' do
      let(:user) { FactoryBot.create(:user, :limited, :internal_admin_user) }
      it { is_expected.to eq(false) }
    end

    context 'when an admin' do
      let(:user) { FactoryBot.create(:user, :limited, :admin) }
      it { is_expected.to eq(false) }
    end

    context 'when an pro_admin' do
      let(:user) { FactoryBot.create(:user, :limited, :pro_admin) }
      it { is_expected.to eq(false) }
    end

    context 'when confirmed_not_spam' do
      let(:user) do
        FactoryBot.create(:user, :limited, confirmed_not_spam: true)
      end

      it { is_expected.to eq(false) }
    end

    context 'when there are info_requests and classifications' do
      let(:user) do
        FactoryBot.create(
          :user, :limited,
          info_requests_count: 1, status_update_count: 1
        )
      end

      it { is_expected.to eq(false) }
    end
  end
end

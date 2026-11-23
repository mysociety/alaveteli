require 'spec_helper'

RSpec.describe Admin::TwoFactorController do
  before(:each) { basic_auth_login(@request) }

  describe 'GET #show' do
    let!(:hotp_user)  { FactoryBot.create(:user, :enable_hotp) }
    let!(:totp_user)  { FactoryBot.create(:user, :enable_totp) }
    let!(:hotp_admin) { FactoryBot.create(:admin_user, :enable_hotp) }
    let!(:totp_admin) { FactoryBot.create(:admin_user, :enable_totp) }

    it 'returns a successful response' do
      get :show
      expect(response).to be_successful
    end

    it 'renders the show template' do
      get :show
      expect(response).to render_template(:show)
    end

    it 'counts HOTP and TOTP users across all users' do
      get :show
      expect(assigns[:all_counts]).to include(hotp: 2, totp: 2)
    end

    it 'counts HOTP and TOTP users scoped to admins' do
      get :show
      expect(assigns[:admin_counts]).to include(hotp: 1, totp: 1)
    end

    it 'assigns the HOTP user cohort' do
      get :show
      expect(assigns[:hotp_users]).to match_array([hotp_user, hotp_admin])
    end

    it 'orders HOTP users by last_sign_in_at desc with nils last' do
      hotp_admin.update!(last_sign_in_at: 1.day.ago)
      hotp_user.update!(last_sign_in_at: 1.year.ago)
      never = FactoryBot.create(:user, :enable_hotp, last_sign_in_at: nil)

      get :show
      expect(assigns[:hotp_users].map(&:id)).
        to eq([hotp_admin.id, hotp_user.id, never.id])
    end
  end
end

require 'spec_helper'

RSpec.describe AdminController do
  controller(AdminController) do
    def index
      head :ok
    end
  end

  describe 'two factor authentication enforcement' do
    let(:admin_user) { FactoryBot.create(:admin_user) }

    after do
      AdminController.require_two_factor_auth = false
    end

    it 'defaults require_two_factor_auth to false' do
      expect(AdminController.require_two_factor_auth).to eq(false)
    end

    context 'when require_two_factor_auth is false (default)' do
      it 'does not redirect a non-2FA admin' do
        sign_in admin_user
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when require_two_factor_auth is true' do
      before do
        AdminController.require_two_factor_auth = true
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)
        allow(AlaveteliConfiguration).
          to receive(:skip_admin_auth).and_return(false)
      end

      it 'redirects a non-2FA admin to the two factor page' do
        sign_in admin_user
        get :index
        expect(response).to redirect_to(one_time_password_path)
      end

      it 'sets a flash explaining the requirement' do
        sign_in admin_user
        get :index
        expect(flash[:error]).to match(/Two factor authentication is required/)
      end

      it 'redirects a HOTP admin to the two factor page' do
        sign_in FactoryBot.create(:admin_user, :enable_hotp)
        get :index
        expect(response).to redirect_to(one_time_password_path)
      end

      it 'allows a TOTP admin through' do
        sign_in FactoryBot.create(:admin_user, :enable_totp)
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'does not enforce when two factor auth is disabled globally' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        sign_in admin_user
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'does not enforce when admin authentication is skipped (external auth)' do
        allow(AlaveteliConfiguration).
          to receive(:skip_admin_auth).and_return(true)
        get :index
        expect(response).to have_http_status(:ok)
      end

      it 'does not enforce for the emergency user (no Alaveteli User)' do
        # Emergency user authenticates via HTTP basic; admin_name is set to a
        # bare string and there is no signed-in Alaveteli User.
        session[:using_admin] = 1
        session[:admin_name] = 'emergency'
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

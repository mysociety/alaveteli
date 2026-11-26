require 'spec_helper'

RSpec.describe AdminUsersSessionsController do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:target_user) { FactoryBot.create(:user) }

  describe 'POST #create' do
    before do
      sign_in admin_user
    end

    it 'remembers the current admin' do
      post :create, params: { id: target_user.id }
      expect(session[:admin_id]).to eq(admin_user.id)
    end

    it 'logs in as another user' do
      post :create, params: { id: target_user.id }
      expect(session[:user_id]).to eq(target_user.id)
    end

    it 'sets the login token to ' do
      post :create, params: { id: target_user.id }
      expect(session[:user_login_token]).to eq(target_user.login_token)
    end

    it 'sets the user_circumstance session to login_as' do
      post :create, params: { id: target_user.id }
      expect(session[:user_circumstance]).to eq('login_as')
    end

    it 'redirects to the target user page' do
      post :create, params: { id: target_user.id }
      expect(response).to redirect_to(user_path(target_user))
    end

    it 'loads target user when next authenticating' do
      post :create, params: { id: target_user.id }
      expect(controller.send(:authenticated_user)).to eq(target_user)
    end

    it 'prevents login in as when already logged in as another user' do
      post :create, params: { id: target_user.id }
      expect { post :create, params: { id: admin_user.id } }.to raise_error(
        AdminUsersSessionsController::AlreadyLoggedInAsError
      )
    end

    context 'with an unconfirmed user' do
      let(:target_user) { FactoryBot.create(:unconfirmed_user) }

      it 'confirms their account' do
        post :create, params: { id: target_user.id }
        expect(target_user.reload.email_confirmed).to eq(true)
      end
    end

    context 'if the user cannot log in as the user' do
      let(:target_user) { FactoryBot.create(:pro_user) }

      it 'redirects to the admin user page for that user' do
        with_feature_enabled(:alaveteli_pro) do
          post :create, params: { id: target_user.id }
          expect(response).to redirect_to(admin_user_path(target_user))
        end
      end

      it 'shows an error message' do
        with_feature_enabled(:alaveteli_pro) do
          post :create, params: { id: target_user.id }
          expect(flash[:error]).
            to eq "You don't have permission to log in as #{ target_user.name }"
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      sign_in target_user
      session[:user_circumstance] = 'login_as'
    end

    it 'clears the current admin' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect(session[:admin_id]).to be_nil
    end

    it 'logs in as admin user' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect(session[:user_id]).to eq(admin_user.id)
    end

    it 'sets the login token' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect(session[:user_login_token]).to eq(admin_user.login_token)
    end

    it 'clears the user_circumstance' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect(session[:user_circumstance]).to be_nil
    end

    it 'redirects to the target admin user page' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect(response).to redirect_to(admin_user_path(target_user))
    end

    it 'prevents reverting when not logged in as another user' do
      delete :destroy, session: { admin_id: admin_user.id }
      expect { delete :destroy, session: { admin_id: admin_user.id }}.
        to raise_error(AdminUsersSessionsController::NotLoggedInAsError)
    end
  end

  describe 'full login as + revert cycle' do
    def check_roundtrip(normal_user, test_admin_user)
      post :create, params: { id: normal_user.id }
      expect(session[:user_id]).to eq(normal_user.id)
      expect(controller.send(:authenticated_user)).to eq(normal_user)

      delete :destroy, session: { admin_id: test_admin_user.id }
      expect(session[:user_id]).to eq(test_admin_user.id)
      expect(session[:admin_id]).to be_nil
      expect(response).to redirect_to(admin_user_path(normal_user))
      expect(session[:user_circumstance]).to be_nil
      expect(controller.send(:authenticated_user).id).to eq(test_admin_user.id)
    end

    context 'with 2FA disabled' do
      before do
        allow(AdminController).
          to receive(:require_two_factor_auth).and_return(false)
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        sign_in admin_user
      end

      it 'redirects to the admin user page' do
        check_roundtrip(target_user, admin_user)
      end
    end

    context 'with 2FA required' do
      let(:totp_admin_user) { FactoryBot.create(:admin_user, :enable_totp) }

      before do
        allow(AdminController).
          to receive(:require_two_factor_auth).and_return(false)
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(true)
        sign_in totp_admin_user
      end

      it 'redirects to the admin user page' do
        check_roundtrip(target_user, totp_admin_user)
      end
    end
  end
end

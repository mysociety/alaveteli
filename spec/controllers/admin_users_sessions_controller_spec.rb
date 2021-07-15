require 'spec_helper'

describe AdminUsersSessionsController do

  describe 'POST #create' do
    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:target_user) { FactoryBot.create(:user) }

    before do
      session[:user_id] = admin_user.id
    end

    it 'logs in as another user' do
      post :create, params: { id: target_user.id }
      expect(session[:user_id]).to eq(target_user.id)
    end

    it 'sets the user_circumstance session to login_as' do
      post :create, params: { id: target_user.id }
      expect(session[:user_circumstance]).to eq('login_as')
    end

    it 'redirects to the target user page' do
      post :create, params: { id: target_user.id }
      expect(response).to redirect_to(user_path(target_user))
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

end

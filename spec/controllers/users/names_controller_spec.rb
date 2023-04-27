require 'spec_helper'

RSpec.describe Users::NamesController do
  describe 'GET edit' do
    context 'without a logged in user' do
      it 'redirects to the home page' do
        sign_in nil
        get :edit
        expect(response).to redirect_to(frontpage_path)
      end
    end

    context 'with a logged in user' do
      let(:user) { FactoryBot.create(:user) }

      it 'assigns the currently logged in user' do
        sign_in user
        get :edit
        expect(assigns[:user]).to eq(user)
      end

      it 'is successful' do
        sign_in user
        get :edit
        expect(response).to be_successful
      end

      it 'renders the edit form' do
        sign_in user
        get :edit
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'PUT update' do
    context 'without a logged in user' do
      it 'redirects to the sign in page' do
        sign_in nil
        put :update, params: { user: { about_me: 'Bobby' } }
        expect(response).to redirect_to(frontpage_path)
      end
    end

    context 'with a banned user' do
      before { sign_in FactoryBot.create(:user, :banned) }

      it 'displays an error' do
        put :update, params: { user: { name: 'Bobby' } }
        expect(flash[:error]).to eq('Suspended users cannot edit their profile')
      end

      it 'redirects to edit' do
        put :update, params: { user: { name: 'Bobby' } }
        expect(response).to redirect_to(edit_profile_about_me_path)
      end
    end

    context 'with valid attributes' do
      let(:user) { FactoryBot.create(:user) }
      before { sign_in user }

      it 'assigns the currently logged in user' do
        put :update, params: { user: { name: 'Bobby' } }
        expect(assigns[:user]).to eq(user)
      end

      it 'updates the user name' do
        put :update, params: { user: { name: 'Bobby' } }
        expect(user.reload.name).to eq('Bobby')
      end
    end

    context 'with bad parameters' do
      before { sign_in FactoryBot.create(:user) }

      it 'can raise missing parameter exeception' do
        expect {
          put :update, params: { name: 'Bobby' }
        }.to raise_error(ActionController::ParameterMissing)
      end

      it 'can raise unpermitted parameter exeception' do
        expect {
          put :update, params: { user: { name: 'Updated text', role_ids: [1] } }
        }.to raise_error(ActionController::UnpermittedParameters)
      end
    end
  end
end

require 'spec_helper'

RSpec.describe AdminUsersAccountErasingController do
  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }

    context 'with valid params for erasing' do
      let(:valid_params) do
        { user_id: user.id }
      end

      before { post :create, params: valid_params }

      it 'finds the user to erase' do
        expect(assigns[:erased_user]).to eq(user)
      end

      it 'redirects to the user page' do
        expect(response).to redirect_to(admin_user_path(user))
      end

      context 'on an open account' do
        it 'tells the admin that the user was not erased' do
          expect(flash[:error]).to eq('Something went wrong. The user could not be erased.')
        end
      end
    end

    context 'with valid params for erasing' do
      let(:valid_params) do
        { user_id: user.id }
      end

      def create
        post :create, params: valid_params
      end

      it 'erases the user' do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        expect(user).to receive(:erase!)
        create
      end
    end

    context 'with invalid params' do
      it 'renders a 404' do
        expect {
          post :create
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'on a closed account' do
      let(:valid_params) do
        { user_id: user.id }
      end

      before do
        user.close
        post :create, params: valid_params
      end

      it 'tells the admin that the user was erased' do
        expect(flash[:notice]).to eq('The user was erased.')
      end
    end
  end
end

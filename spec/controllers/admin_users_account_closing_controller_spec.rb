require 'spec_helper'

RSpec.describe AdminUsersAccountClosingController do
  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }

    context 'with valid params for closing' do
      let(:valid_params) do
        { user_id: user.id }
      end

      before { post :create, params: valid_params }

      it 'finds the user to close' do
        expect(assigns[:closed_user]).to eq(user)
      end

      it 'tells the admin that the user was closed' do
        expect(flash[:notice]).to eq('The user account was closed.')
      end

      it 'redirects to the user edit page' do
        expect(response).to redirect_to(edit_admin_user_path(user))
      end
    end

    context 'with valid params for closing' do
      let(:valid_params) do
        { user_id: user.id }
      end

      def create
        post :create, params: valid_params
      end

      it 'closes the user' do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        expect(user).to receive(:close!)
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
  end
end

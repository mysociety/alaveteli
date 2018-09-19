# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AdminUsersAccountSuspensionsController do

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }

    context 'with valid params for banning' do
      let(:valid_params) do
        { user_id: user.id, suspension_reason: 'Banned for spamming' }
      end

      before { post :create, valid_params }

      it 'finds the user to suspend' do
        expect(assigns[:suspended_user]).to eq(user)
      end

      it 'sets the suspension reason' do
        expect(assigns[:suspension_reason]).to eq('Banned for spamming')
      end

      it 'bans the user' do
        expect(user.reload.ban_text).to eq('Banned for spamming')
      end

      it 'tells the admin that the user was banned' do
        expect(flash[:notice]).to eq('The user was suspended.')
      end

      it 'redirects to the user page' do
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context 'with valid params for closing' do
      let(:valid_params) do
        { user_id: user.id, close_and_anonymise: true }
      end

      before { post :create, valid_params }

      it 'finds the user to suspend' do
        expect(assigns[:suspended_user]).to eq(user)
      end

      it 'closes the user' do
        expect { user.reload }.to change(user, :closed?).to(true)
      end

      it 'tells the admin that the user was banned' do
        expect(flash[:notice]).to eq('The user was suspended.')
      end

      it 'redirects to the user page' do
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context 'with invalid params' do
      it 'renders a 404' do
        expect { post :create, {} }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without a suspension_reason' do
      before { post :create, user_id: user.id }

      it 'sets a default suspension reason' do
        default = 'Account suspended – Please contact us'
        expect(assigns[:suspension_reason]).to eq(default)
      end
    end

  end

end

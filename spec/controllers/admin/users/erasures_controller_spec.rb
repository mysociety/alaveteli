require 'spec_helper'

RSpec.describe Admin::Users::ErasuresController do
  describe 'POST #create' do
    subject { post :create, params: params }

    let(:admin_user) { FactoryBot.create(:admin_user) }
    let(:user) { FactoryBot.create(:user) }

    let(:params) do
      { user_id: user.id, reason: 'GDPR' }
    end

    before do
      sign_in(admin_user)
      allow(@controller).
        to receive(:admin_current_user).and_return(admin_user.name)
    end

    context 'with valid params for erasing' do
      before { user.close }

      it 'finds the user to erase' do
        subject
        expect(assigns[:erased_user]).to eq(user)
      end

      it 'enqueues a User::ErasureJob' do
        expect { subject }.
          to have_enqueued_job(User::ErasureJob).
          with(user, editor: admin_user.name, reason: 'GDPR')
      end

      it 'redirects to the user page' do
        subject
        expect(response).to redirect_to(admin_user_path(user))
      end

      it 'tells the admin that the erasure will be processed' do
        subject
        expect(flash[:notice]).to eq('Erasure has been queued.')
      end
    end

    context 'when an account is not closed' do
      it 'does not enqueue a User::ErasureJob' do
        expect { subject }.not_to have_enqueued_job(User::ErasureJob)
      end

      it 'redirects to the user page' do
        subject
        expect(response).to redirect_to(admin_user_path(user))
      end

      it 'tells the admin that the user cannot be erased' do
        subject
        expect(flash[:error]).
          to eq('User accounts must be closed before erasing.')
      end
    end

    context 'with invalid params' do
      let(:params) do
        { user_id: 0 }
      end

      it 'renders a 404' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

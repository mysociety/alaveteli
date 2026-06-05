require 'spec_helper'

RSpec.describe Users::TwoFactorChallengesController do
  before do
    # Don't call out to external url during tests
    allow(controller).to receive(:country_from_ip).and_return('gb')
  end

  let(:user) { FactoryBot.create(:user, :enable_totp) }
  let(:valid_code) { user.otp_code }
  let(:invalid_code) { valid_code == '000000' ? '000001' : '000000' }
  let(:post_redirect) do
    FactoryBot.create(:post_redirect, uri: request_list_path)
  end

  def start_pending_sign_in
    PendingTwoFactorSignIn.new(session).start(
      user: user, remember_me: false, post_redirect: post_redirect
    )
  end

  describe 'GET new' do
    it 'renders the challenge form for a pending sign-in' do
      start_pending_sign_in
      get :new
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
    end
  end

  describe 'POST create' do
    context 'with a valid code' do
      before do
        start_pending_sign_in
        post :create, params: { otp_code: valid_code }
      end

      it 'signs the user in' do
        expect(session[:user_id]).to eq(user.id)
      end

      it 'clears the pending sign-in state' do
        expect(session[:pending_2fa_user_id]).to be_nil
      end

      it 'redirects to the stashed destination' do
        expect(response).to redirect_to(request_list_path(post_redirect: 1))
      end
    end

    context 'with an invalid code' do
      before do
        start_pending_sign_in
        post :create, params: { otp_code: invalid_code }
      end

      it 'does not sign the user in' do
        expect(session[:user_id]).to be_nil
      end

      it 're-renders the challenge' do
        expect(response).to render_template(:new)
      end

      it 'shows an error' do
        expect(flash[:error]).to be_present
      end

      it 'keeps the pending sign-in state' do
        expect(session[:pending_2fa_user_id]).to eq(user.id)
      end
    end

    context 'with a blank code' do
      before { start_pending_sign_in }

      it 'does not sign the user in and re-renders' do
        post :create, params: { otp_code: '' }
        expect(session[:user_id]).to be_nil
        expect(response).to render_template(:new)
      end
    end

    context 'when the attempt limit is exceeded' do
      before do
        start_pending_sign_in
        described_class.cache_store.clear
        # One more than the limit allows, so the final attempt is throttled.
        6.times { post :create, params: { otp_code: invalid_code } }
      end

      it 're-renders the challenge with a rate-limit error' do
        expect(response).to render_template(:new)
        expect(flash[:error]).to match(/Too many attempts/)
      end

      it 'keeps the pending sign-in so the password check is not repeated' do
        expect(session[:pending_2fa_user_id]).to eq(user.id)
      end
    end
  end

  describe 'guarding the pending sign-in' do
    context 'without a pending sign-in' do
      it 'redirects GET new to sign in' do
        get :new
        expect(response).to redirect_to(signin_path)
      end

      it 'does not sign anyone in on create, even with a valid code' do
        post :create, params: { otp_code: valid_code }
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(signin_path)
      end
    end

    context 'when the pending sign-in has expired' do
      before { start_pending_sign_in }

      it 'redirects to sign in' do
        travel(PendingTwoFactorSignIn::TTL + 1.minute) do
          get :new
          expect(response).to redirect_to(signin_path)
        end
      end
    end

    context 'when the user disabled two factor mid-flow' do
      before do
        start_pending_sign_in
        user.disable_otp
        user.save!
      end

      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(signin_path)
      end
    end
  end
end

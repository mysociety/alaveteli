require 'spec_helper'

RSpec.describe OneTimePasswordsController do
  before :each do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  describe 'GET new' do
    render_views

    let(:user) { FactoryBot.create(:user) }

    it 'redirects to the sign-in page without a signed in user' do
      get :new

      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'renders an SVG QR code and the base32 fallback in the response' do
      sign_in user
      get :new

      expect(session[:pending_otp_secret_key]).to be_present
      expect(response.body).to include('<svg')
      expect(response.body).to include(session[:pending_otp_secret_key])
    end

    it 'reuses an existing candidate secret across refreshes' do
      sign_in user
      existing_secret = ROTP::Base32.random
      session[:pending_otp_secret_key] = existing_secret
      get :new

      expect(session[:pending_otp_secret_key]).to eq(existing_secret)
    end

    it 'exposes an enrolment for the candidate to the view' do
      sign_in user
      get :new

      expect(assigns[:enrolment]).to be_a(OtpEnrolment)
      expect(assigns[:enrolment].secret).
        to eq(session[:pending_otp_secret_key])
    end

    it 'does not modify the persisted user record' do
      original_secret = user.otp_secret_key
      original_counter = user.otp_counter
      original_enabled = user.otp_enabled

      sign_in user
      get :new

      user.reload
      expect(user.otp_secret_key).to eq(original_secret)
      expect(user.otp_counter).to eq(original_counter)
      expect(user.otp_enabled).to eq(original_enabled)
    end

    context 'when the user is currently HOTP-enabled' do
      it 'does not touch the persisted HOTP secret or counter' do
        user = FactoryBot.create(:user, :enable_hotp)
        original_secret = user.otp_secret_key
        original_counter = user.otp_counter

        sign_in user
        get :new

        user.reload
        expect(user.otp_secret_key).to eq(original_secret)
        expect(user.otp_counter).to eq(original_counter)
        expect(user.otp_enabled).to eq(true)
      end
    end
  end

  describe 'GET show' do
    render_views

    it 'redirects to the sign-in page without a signed in user' do
      get :show

      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      user = FactoryBot.create(:user)

      sign_in user
      get :show

      expect(assigns[:user]).to eq(user)
    end

    it 'renders the show template' do
      user = FactoryBot.create(:user)

      sign_in user
      get :show

      expect(response).to render_template('show')
    end

    context 'for a TOTP-enabled user' do
      let(:user) { FactoryBot.create(:user, :enable_totp) }

      before { sign_in user }

      it 'does not render a live OTP code' do
        get :show

        expect(response.body).not_to include(user.otp_code)
      end

      it 'renders a disable link' do
        get :show

        expect(response.body).to match(/disable two factor/i)
      end

      it 'does not render a regenerate link' do
        get :show

        expect(response.body).not_to match(/regenerate/i)
      end

      context 'with a just-upgraded-from-HOTP flash' do
        it 'renders the discard-old-passcode block' do
          get :show, flash: { just_upgraded_from_hotp: true }

          expect(response.body).
            to match(/Discard your previous one time passcode/i)
        end
      end

      context 'without the just-upgraded-from-HOTP flash' do
        it 'does not render the discard-old-passcode block' do
          get :show

          expect(response.body).
            not_to match(/Discard your previous one time passcode/i)
        end
      end
    end

    context 'for a HOTP-enabled user' do
      let(:user) { FactoryBot.create(:user, :enable_hotp) }

      before { sign_in user }

      it 'still renders the current HOTP code' do
        get :show

        expect(response.body).to include(user.otp_code)
      end

      it 'renders an upgrade CTA linking to the enrolment page' do
        get :show

        expect(response.body).to match(/Upgrade to authenticator app/i)
        expect(response.body).to include(new_one_time_password_path)
      end
    end

    context 'for a user with no 2FA' do
      let(:user) { FactoryBot.create(:user) }

      before { sign_in user }

      it 'renders a link to the enrolment page' do
        get :show

        expect(response.body).to include(new_one_time_password_path)
        expect(response.body).to match(/Enable two factor authentication/i)
      end
    end

    context 'when 2factor auth is not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        expect {
          get :show
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryBot.create(:user) }
    let(:candidate_secret) { ROTP::Base32.random }
    let(:valid_code) { ROTP::TOTP.new(candidate_secret).now }

    it 'redirects to the sign-in page without a signed in user' do
      post :create
      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      sign_in user
      post :create
      expect(assigns[:user]).to eq(user)
    end

    context 'with a valid code and a candidate in the session' do
      before do
        sign_in user
        session[:pending_otp_secret_key] = candidate_secret
      end

      it 'clears the pending candidate from the session' do
        post :create, params: { otp_enrolment: { otp_code: valid_code } }

        expect(session[:pending_otp_secret_key]).to be_nil
      end

      it 'redirects to the two factor settings page' do
        post :create, params: { otp_enrolment: { otp_code: valid_code } }

        expect(response).to redirect_to(one_time_password_path)
      end

      it 'sets a success notice' do
        post :create, params: { otp_enrolment: { otp_code: valid_code } }

        expect(flash[:notice]).to eq('Two factor authentication enabled')
      end

      context 'and the user had no 2FA before' do
        it 'does not set the upgrade-from-HOTP flag' do
          post :create, params: { otp_enrolment: { otp_code: valid_code } }

          expect(flash[:just_upgraded_from_hotp]).to be_nil
        end
      end

      context 'and the user was previously on HOTP' do
        let(:user) { FactoryBot.create(:user, :enable_hotp) }

        it 'sets the upgrade-from-HOTP flag for the redirect target' do
          expect(user.hotp?).to eq(true)

          post :create, params: { otp_enrolment: { otp_code: valid_code } }

          expect(flash[:just_upgraded_from_hotp]).to eq(true)
        end
      end
    end

    context 'with an invalid code' do
      let(:invalid_code) { valid_code == '000000' ? '000001' : '000000' }

      before do
        sign_in user
        session[:pending_otp_secret_key] = candidate_secret
      end

      it 'preserves the candidate secret in the session' do
        post :create, params: { otp_enrolment: { otp_code: invalid_code } }

        expect(session[:pending_otp_secret_key]).to eq(candidate_secret)
      end

      it 're-renders the new template' do
        post :create, params: { otp_enrolment: { otp_code: invalid_code } }

        expect(response).to render_template(:new)
      end

      it 'populates an error on the enrolment form object' do
        post :create, params: { otp_enrolment: { otp_code: invalid_code } }

        expect(assigns[:enrolment].errors[:otp_code]).to be_present
      end
    end

    context 'with no candidate in the session' do
      before { sign_in user }

      it 'redirects to the new enrolment page' do
        post :create, params: { otp_enrolment: { otp_code: '123456' } }

        expect(response).to redirect_to(new_one_time_password_path)
      end

      it 'does not modify the user record' do
        original_enabled = user.otp_enabled

        post :create, params: { otp_enrolment: { otp_code: '123456' } }

        expect(user.reload.otp_enabled).to eq(original_enabled)
      end

      it 'sets a flash explaining the setup expired' do
        post :create, params: { otp_enrolment: { otp_code: '123456' } }

        expect(flash[:notice]).
          to match(/two factor authentication setup expired/i)
      end
    end

    context 'when 2factor auth is not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        expect {
          post :create
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'PUT #update' do
    it 'redirects to the sign-in page without a signed in user' do
      put :update
      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      user = FactoryBot.create(:user)
      sign_in user
      put :update
      expect(assigns[:user]).to eq(user)
    end

    it 'regenerates the otp_code' do
      user = FactoryBot.create(:user, otp_enabled: true, otp_counter: 1)
      expected = ROTP::HOTP.new(user.otp_secret_key).at(2)
      sign_in user
      put :update
      expect(user.reload.otp_code).to eq(expected)
    end

    it 'sets a successful notification message' do
      user = FactoryBot.create(:user, otp_enabled: true)
      sign_in user
      put :update
      expect(flash[:notice]).to eq('Two factor one time passcode updated')
    end

    it 'redirects back to #show on success' do
      user = FactoryBot.create(:user, otp_enabled: true)
      sign_in user
      put :update
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'renders #show on failure' do
      user = FactoryBot.create(:user, otp_enabled: true)
      allow_any_instance_of(User).
        to receive(:increment!).and_return(false)
      sign_in user
      put :update
      expect(response).to render_template(:show)
    end

    it 'warns the user on failure' do
      user = FactoryBot.create(:user, otp_enabled: true)
      allow_any_instance_of(User).
        to receive(:increment!).and_return(false)
      sign_in user
      put :update
      expect(flash[:error]).
        to eq('Could not update your two factor one time passcode')
    end

    context 'when 2factor auth is not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        expect {
          put :update
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'redirects to the sign-in page without a signed in user' do
      user = FactoryBot.create(:user)
      delete :destroy
      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'assigns the signed in user' do
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy
      expect(assigns[:user]).to eq(user)
    end

    it 'disables OTP for the user' do
      user = FactoryBot.create(:user, :enable_hotp)
      sign_in user
      delete :destroy
      expect(user.reload.otp_enabled?).to eq(false)
    end

    it 'sets a successful notification message' do
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy
      expect(flash[:notice]).to eq('Two factor authentication disabled')
    end

    it 'redirects back to #show on success' do
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'sets a failure notification message' do
      allow_any_instance_of(User).to receive(:save).and_return(false)
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy
      expect(flash[:error]).
        to eq('Two factor authentication could not be disabled')
    end

    it 'renders #show on failure' do
      allow_any_instance_of(User).to receive(:save).and_return(false)
      user = FactoryBot.create(:user)
      sign_in user
      delete :destroy
      expect(response).to render_template(:show)
    end

    context 'when two factor auth is not enabled' do
      it 'raises ActiveRecord::RecordNotFound' do
        allow(AlaveteliConfiguration).
          to receive(:enable_two_factor_auth).and_return(false)
        expect {
          delete :destroy
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

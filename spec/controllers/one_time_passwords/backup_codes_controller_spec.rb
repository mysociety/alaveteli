require 'spec_helper'

RSpec.describe OneTimePasswords::BackupCodesController do
  before :each do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  let(:user) { FactoryBot.create(:user, :enable_totp) }
  let(:valid_code) { user.otp_code }
  let(:invalid_code) { valid_code == '000000' ? '000001' : '000000' }

  describe 'GET show' do
    it 'redirects to the sign-in page without a signed in user' do
      get :show
      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    it 'redirects a HOTP user to the two factor settings page' do
      hotp_user = FactoryBot.create(:user, :enable_hotp)
      sign_in hotp_user
      get :show
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'redirects a user without 2FA to the two factor settings page' do
      sign_in FactoryBot.create(:user)
      get :show
      expect(response).to redirect_to(one_time_password_path)
    end

    it 'renders the management page for a TOTP user' do
      sign_in user
      get :show
      expect(response).to render_template(:show)
    end

    it 'raises ActiveRecord::RecordNotFound when 2factor auth is disabled' do
      allow(AlaveteliConfiguration).
        to receive(:enable_two_factor_auth).and_return(false)
      sign_in user

      expect { get :show }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST create' do
    it 'redirects to the sign-in page without a signed in user' do
      post :create
      expect(response).
        to redirect_to(signin_path(token: PostRedirect.last.token))
    end

    context 'with a valid code from the authenticator app' do
      before { sign_in user }

      it 'issues a fresh set of backup codes' do
        expect { post :create, params: { otp_code: valid_code } }.
          to change { user.reload.otp_backup_codes }
        expect(user.otp_backup_codes.size).to eq(12)
        expect(user.otp_backup_codes_generated_at).to be_present
      end

      it 'replaces any existing codes' do
        old_codes = user.otp_regenerate_backup_codes
        user.save!

        post :create, params: { otp_code: valid_code }

        expect(user.reload.authenticate_otp(old_codes.first)).to eq(false)
      end

      it 'passes the new plaintext codes to the redirect target' do
        post :create, params: { otp_code: valid_code }

        expect(flash[:backup_codes].size).to eq(12)
      end

      it 'redirects back to the management page with a notice' do
        post :create, params: { otp_code: valid_code }

        expect(response).to redirect_to(one_time_password_backup_codes_path)
        expect(flash[:notice]).to eq('New backup codes generated')
      end
    end

    context 'with a valid backup code as the confirmation code' do
      before { sign_in user }

      it 'issues a fresh set of backup codes' do
        old_codes = user.otp_regenerate_backup_codes
        user.save!

        post :create, params: { otp_code: old_codes.first }

        expect(flash[:backup_codes].size).to eq(12)
        expect(response).to redirect_to(one_time_password_backup_codes_path)
      end
    end

    context 'with an invalid code' do
      before { sign_in user }

      it 'does not change the stored codes' do
        user.otp_regenerate_backup_codes
        user.save!

        expect { post :create, params: { otp_code: invalid_code } }.
          not_to change { user.reload.otp_backup_codes }
      end

      it 're-renders the management page with an error' do
        post :create, params: { otp_code: invalid_code }

        expect(response).to render_template(:show)
        expect(flash[:error]).to be_present
      end
    end

    context 'with no code' do
      before { sign_in user }

      it 're-renders the management page with an error' do
        post :create

        expect(response).to render_template(:show)
        expect(flash[:error]).to be_present
      end

      it 'does not issue codes' do
        post :create

        expect(user.reload.otp_backup_codes).to be_empty
      end
    end
  end
end

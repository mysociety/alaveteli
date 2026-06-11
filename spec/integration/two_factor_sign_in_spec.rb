require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'signing in with two factor authentication' do
  before do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  def submit_credentials(user)
    visit signin_path
    within '#signin_form' do
      fill_in 'Your e-mail:', with: user.email
      fill_in 'Password:', with: 'jonespassword'
      click_button 'Sign in'
    end
  end

  context 'as a TOTP user' do
    let(:user) { FactoryBot.create(:user, :enable_totp) }

    it 'challenges for a code and signs in once it is correct' do
      using_session(without_login) do
        submit_credentials(user)

        expect(page).to have_current_path(signin_two_factor_path)
        expect(page).
          to have_content('Enter a current code from your authenticator app')
        expect(page).to have_field('Code from your authenticator app')
        expect(page).to have_no_content(user.name)

        valid_code = user.otp_code
        invalid_code = valid_code == '000000' ? '000001' : '000000'

        fill_in 'Code from your authenticator app', with: invalid_code
        click_button 'Verify'

        expect(page).to have_content('Invalid one time password')
        expect(page).to have_no_content(user.name)

        fill_in 'Code from your authenticator app', with: valid_code
        click_button 'Verify'

        expect(page).to have_content(user.name)
      end
    end

    it 'accepts a backup code in place of an authenticator code' do
      codes = user.otp_regenerate_backup_codes
      user.save!

      using_session(without_login) do
        submit_credentials(user)

        expect(page).
          to have_content('If you have lost access to your authenticator ' \
                          'app, you can enter one of your backup codes ' \
                          'instead')

        fill_in 'Code from your authenticator app', with: codes.first
        click_button 'Verify'

        expect(page).to have_content(user.name)
      end
    end
  end

  context 'as a HOTP user' do
    let(:user) { FactoryBot.create(:user, :enable_hotp) }

    it 'signs in without a two factor challenge' do
      using_session(without_login) do
        submit_credentials(user)

        expect(page).
          to have_no_field('Code from your authenticator app')
        expect(page).to have_content(user.name)
      end
    end
  end
end

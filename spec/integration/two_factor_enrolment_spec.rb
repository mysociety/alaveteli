require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'enrolling in two factor authentication' do
  before do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  def base32_secret_on_page
    page.find('ol li code').text
  end

  def complete_enrolment_with_valid_code
    secret = base32_secret_on_page
    fill_in 'Code from your authenticator app',
            with: ROTP::TOTP.new(secret).now
    click_button 'Enable two factor authentication'
    secret
  end

  context 'as a user with no 2FA' do
    let(:user) { FactoryBot.create(:user) }

    it 'walks from the settings page to a working TOTP setup' do
      using_session(login(user)) do
        visit one_time_password_path
        click_link 'Enable two factor authentication'

        expect(page).to have_content('Set up two factor authentication')
        expect(page).to have_css('svg')

        secret = complete_enrolment_with_valid_code

        expect(page).
          to have_content('Two factor authentication enabled')
        expect(page).
          to have_content('Two factor authentication is active on your account')
        expect(page).
          not_to have_content('Discard your previous one time passcode')

        user.reload
        expect(user.otp_secret_key).to eq(secret)
        expect(user.otp_counter).to be_nil
        expect(user.otp_enabled).to eq(true)
        expect(user.otp_enabled_at).to be_within(1.minute).of(Time.zone.now)
        expect(user.totp?).to eq(true)
      end
    end
  end

  context 'as a user already on HOTP' do
    let(:user) { FactoryBot.create(:user, :enable_otp) }

    before { user.save! }

    it 'upgrades the user to TOTP and shows the discard-old-passcode block' do
      original_hotp_secret = user.otp_secret_key

      using_session(login(user)) do
        visit one_time_password_path
        click_link 'Upgrade to authenticator app'

        expect(page).to have_content('Set up two factor authentication')

        new_secret = complete_enrolment_with_valid_code

        expect(page).
          to have_content('Discard your previous one time passcode')
        expect(page).
          to have_content('Delete the passcode saved in your password manager')

        expect(new_secret).not_to eq(original_hotp_secret)

        user.reload
        expect(user.otp_secret_key).to eq(new_secret)
        expect(user.otp_counter).to be_nil
        expect(user.otp_enabled).to eq(true)
        expect(user.totp?).to eq(true)
        expect(user.hotp?).to eq(false)
      end
    end
  end

  context 'with an invalid code' do
    let(:user) { FactoryBot.create(:user) }

    it 'leaves the user record untouched and re-renders the form' do
      using_session(login(user)) do
        visit new_one_time_password_path

        valid_code = ROTP::TOTP.new(base32_secret_on_page).now
        wrong_code = valid_code == '000000' ? '000001' : '000000'
        fill_in 'Code from your authenticator app', with: wrong_code
        click_button 'Enable two factor authentication'

        expect(page).
          to have_content('That code did not match')
        expect(page).to have_content('Set up two factor authentication')

        user.reload
        expect(user.otp_enabled).to eq(false)
        expect(user.totp?).to eq(false)
      end
    end
  end
end

require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'disabling two factor authentication' do
  before do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  context 'as a TOTP user' do
    let(:user) { FactoryBot.create(:user, :enable_totp) }

    it 'requires a current authenticator code to disable' do
      using_session(login(user)) do
        page.driver.submit :delete, one_time_password_path, {}

        expect(page).
          to have_content('Disabling two factor authentication will remove')
        expect(page).
          to have_field('Code from your authenticator app')

        valid_code = user.otp_code
        invalid_code = valid_code == '000000' ? '000001' : '000000'

        fill_in 'Code from your authenticator app', with: invalid_code
        click_button 'Disable two factor authentication'

        expect(page).to have_content('Invalid one time password')
        expect(user.reload.otp_enabled).to eq(true)

        fill_in 'Code from your authenticator app', with: valid_code
        click_button 'Disable two factor authentication'

        expect(page).
          to have_content('Two factor authentication disabled')
        expect(user.reload.otp_enabled).to eq(false)
      end
    end
  end

  context 'as a HOTP user' do
    let(:user) { FactoryBot.create(:user, :enable_hotp) }

    it 'disables without prompting for a code' do
      using_session(login(user)) do
        page.driver.submit :delete, one_time_password_path, {}

        expect(user.reload.otp_enabled).to eq(false)
      end
    end
  end
end

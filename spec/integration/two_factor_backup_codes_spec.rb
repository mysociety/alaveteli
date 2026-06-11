require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'managing two factor backup codes' do
  before do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
  end

  let(:user) { FactoryBot.create(:user, :enable_totp) }

  it 'regenerates codes from the management page' do
    user.otp_regenerate_backup_codes
    user.save!

    using_session(login(user)) do
      # The sign-in challenge consumed the current TOTP code; move past its
      # 30 second window so the confirmation code is fresh.
      travel(31.seconds) do
        visit one_time_password_path
        click_link 'Manage backup codes'

        expect(page).to have_content('Backup codes')

        fill_in 'Code from your authenticator app',
                with: user.otp_code
        click_button 'Generate new backup codes'

        expect(page).to have_content('New backup codes generated')
        expect(page).to have_content('Save these codes somewhere safe')

        new_codes = page.all('.backup-codes__list code').map(&:text)
        expect(new_codes.size).to eq(12)
      end
    end
  end

  it 'rejects regeneration with a wrong code' do
    user.otp_regenerate_backup_codes
    user.save!

    using_session(login(user)) do
      visit one_time_password_backup_codes_path

      valid_code = user.otp_code
      wrong_code = valid_code == '000000' ? '000001' : '000000'
      fill_in 'Code from your authenticator app', with: wrong_code
      click_button 'Generate new backup codes'

      expect(page).to have_content('Invalid one time password')
    end
  end
end

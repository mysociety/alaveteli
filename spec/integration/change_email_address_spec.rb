require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'changing your email address' do
  let(:user) { FactoryBot.create(:user, email: 'oldbob@localhost') }

  it "sends a confirmation email if you get all the details right" do
    using_session(login(user)) do
      visit signchangeemail_path
      fill_in "signchangeemail_old_email", with: user.email
      fill_in "signchangeemail_password", with: 'jonespassword'
      fill_in "signchangeemail_new_email", with: 'newbob@localhost'
      click_button "Change email on Alaveteli"

      expect(page).to have_content('Now check your email!')

      mail = ActionMailer::Base.deliveries.first
      expect(mail.body).to include("confirm that you want to change")
      expect(mail.to).to eq([ 'oldbob@localhost' ])

      # Check confirmation URL works
      visit confirmation_url_from_email
      expect(page).to have_current_path("/user/#{user.url_name}")
      expect(page).to have_content('You have now changed your email address')
      user.reload
      expect(user.email).to eq('newbob@localhost')
      expect(user.email_confirmed).to eq(true)
    end
  end

  context "when the user has TOTP two factor authentication enabled" do
    let(:user) do
      FactoryBot.create(:user, :enable_totp, email: 'oldbob@localhost')
    end

    it "challenges for a code before completing the change" do
      using_session(login(user)) do
        visit signchangeemail_path
        fill_in "signchangeemail_old_email", with: user.email
        fill_in "signchangeemail_password", with: 'jonespassword'
        fill_in "signchangeemail_new_email", with: 'newbob@localhost'
        click_button "Change email on Alaveteli"

        expect(page).to have_content('Now check your email!')

        confirmation_url = confirmation_url_from_email

        # Travel forward for a fresh authenticator code: the login above
        # already consumed the current one, and TOTP rejects replays.
        travel(1.minute) do
          # The confirmation link must not sign the user in directly; it hands
          # off to the two factor challenge first.
          visit confirmation_url
          expect(page).to have_content('Two factor authentication')

          fill_in 'Code from your authenticator app', with: user.otp_code
          click_button 'Verify'
        end

        # Only after passing the challenge does the change complete.
        expect(page).to have_current_path("/user/#{user.url_name}")
        expect(page).to have_content('You have now changed your email address')
        user.reload
        expect(user.email).to eq('newbob@localhost')
        expect(user.email_confirmed).to eq(true)
      end
    end
  end
end

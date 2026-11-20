require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe "When administering the site" do
  let(:target_user_name) { "Tarr Gett" }
  let(:target_user) { FactoryBot.create(:user, name: target_user_name) }
  let(:admin_user) { FactoryBot.create(:admin_user) }

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
  end

  context "when 2fa is disabled an admin" do
    before do
      AdminController.require_two_factor_auth = false
      allow(AlaveteliConfiguration).
        to receive(:enable_two_factor_auth).and_return(false)

      confirm(:admin_user)
      @admin = login(:admin_user)
    end

    it "can log in as another user and revert back" do
      using_session(@admin) do
        visit admin_user_path target_user
        find_link("Log in as #{target_user_name} (also confirms their email)").click
        expect(page).to have_content "Logged in as #{target_user_name}"
        expect(page).to have_content "#{target_user_name} (you)"

        find_link("Revert back to admin").click
        expect(page.current_path).to eq(admin_user_path(target_user.id))
        expect(page).not_to have_content "Logged in as #{target_user_name}"
      end
    end
  end

  context "when 2fa is required an admin with 2fa enabled" do
    let(:totp_admin_user) { FactoryBot.create(:admin_user, :enable_totp) }

    before do
      AdminController.require_two_factor_auth = true
      allow(AlaveteliConfiguration).
        to receive(:enable_two_factor_auth).and_return(true)

      @admin = login(totp_admin_user)
    end

    it "can log in as another user and revert back" do
      using_session(@admin) do
        expect(totp_admin_user.totp?).to eq(true)
        visit admin_user_path target_user
        find_link("Log in as #{target_user_name} (also confirms their email)").click
        expect(page).to have_content "Logged in as #{target_user_name}"
        expect(page).to have_content "#{target_user_name} (you)"

        find_link("Revert back to admin").click
        expect(page.current_path).to eq(admin_user_path(target_user.id))
        expect(page).not_to have_content "Logged in as #{target_user_name}"
      end
    end
  end
end

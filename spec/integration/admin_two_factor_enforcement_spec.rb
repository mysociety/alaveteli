require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'admin two factor authentication enforcement' do
  let(:admin_user) { FactoryBot.create(:admin_user) }

  before do
    allow(AlaveteliConfiguration).
      to receive(:enable_two_factor_auth).and_return(true)
    allow(AlaveteliConfiguration).
      to receive(:skip_admin_auth).and_return(false)
    AdminController.require_two_factor_auth = true
  end

  after do
    AdminController.require_two_factor_auth = false
  end

  context 'as an admin without TOTP enabled' do
    it 'redirects to the two factor page with a prompt to enable it' do
      using_session(login(admin_user)) do
        visit admin_general_index_path

        expect(page).to have_current_path(one_time_password_path)
        expect(page).to have_content(
          'Two factor authentication is required for admins'
        )
      end
    end
  end

  context 'as an admin with TOTP enabled' do
    let(:admin_user) { FactoryBot.create(:admin_user, :enable_totp) }

    it 'reaches the admin interface without further prompts' do
      using_session(login(admin_user)) do
        visit admin_general_index_path

        expect(page).to have_current_path(admin_general_index_path)
      end
    end
  end
end

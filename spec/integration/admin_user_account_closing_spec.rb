require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe 'Admin Account Closure Requests' do
  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)

    confirm(:admin_user)
    @admin = login(:admin_user)
    @user = FactoryBot.create(:user)
    @account_closure_request = FactoryBot.create(
      :account_closure_request,
      user: @user
    )
  end

  context 'viewing account closure requests' do
    it 'displays link to "Account closure requests" on admin homepage' do
      using_session(@admin) do
        visit admin_general_index_path
        expect(page).to have_link('Account closure requests')
      end
    end

    it 'can close an account from the "Account closure requests" page' do
      using_session(@admin) do
        expect(@user).to_not be_closed

        visit account_closure_requests_admin_users_path
        within("tr#account-closure-request-#{@account_closure_request.id}") do
          click_button 'Close'
        end
        expect(page).to have_text('The user account was closed.')

        @user.reload
        expect(@user).to be_closed

        visit account_closure_requests_admin_users_path
        expect(page).to_not have_text(@user.name)
      end
    end
  end
end

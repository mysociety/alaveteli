# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When creating requests" do

  it "should associate the request with the requestor, even if it is approved by an admin" do
    using_session(without_login) do
      # This is a test for https://github.com/mysociety/alaveteli/issues/446
      create_request
      # Now log in as an unconfirmed user.
      visit signin_path :token => get_last_post_redirect.token
      within '#signin_form' do
        fill_in "Your e-mail:", :with => users(:unconfirmed_user).email
        fill_in "Password:", :with => "jonespassword"
        click_button "Sign in"
      end
      expect(page).to have_content('Now check your email!')
    end

    # This will trigger a confirmation mail. Get the PostRedirect for later.
    post_redirect = get_last_post_redirect
    # Now log in as an admin user, then follow the confirmation link in the email that was sent to the unconfirmed user
    confirm(:admin_user)
    admin = login(:admin_user)
    using_session(admin) do
      visit confirm_path(:email_token => post_redirect.email_token)

      expect(current_url).to match(%r(/request/(.+)/new))
      current_url =~ %r(/request/(.+)/new)
      url_title = $1
      info_request = InfoRequest.find_by_url_title(url_title)
      expect(info_request).not_to be_nil

      # Make sure the request is still owned by the user who made it, not the admin who confirmed it
      expect(info_request.user_id).to eq(users(:unconfirmed_user).id)
    end

  end

end

# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/alaveteli_dsl'

describe "When creating requests" do

  before :all do
    get_fixtures_xapian_index
  end

  let!(:admin_user) { FactoryGirl.create(:admin_user) }
  let!(:public_body) do
    FactoryGirl.create(:public_body,
                       :name => 'example')
  end
  let!(:admin_user_session) { login(admin_user) }

  before do
    update_xapian_index
  end

  it <<-EOF do
      should associate the request with the requestor, even if it is approved
      by an admin
    EOF
    post_redirect = create_request_and_user(public_body)
    # Now log in as an admin user, then follow the confirmation link in the
    # email that was sent to the unconfirmed user
    using_session(admin_user_session) do
      visit confirm_path(:email_token => post_redirect.email_token)

      expect(current_url).to match(%r(/request/(.+)))
      current_url =~ %r(/request/(.+))
      url_title = $1
      info_request = InfoRequest.find_by_url_title(url_title)
      expect(info_request).not_to be_nil

      # Make sure the request is still owned by the user who made it,
      # not the admin who confirmed it
      expect(info_request.user_id).to eq(post_redirect.user_id)
    end

  end

end

# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/alaveteli_dsl'

describe "When creating requests" do

  before do
    get_fixtures_xapian_index
  end

  let!(:admin_user) { FactoryBot.create(:admin_user) }
  let!(:public_body) { FactoryBot.create(:public_body, name: 'example') }
  let!(:admin_user_session) { login(admin_user) }

  before do
    update_xapian_index
  end

  it 'associates the request with the requestor, even if it is approved by an admin' do
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

  context 'the authority name contains an apostrophe' do

    let(:user) { FactoryBot.create(:user) }
    let(:user_session) { login(user) }
    let(:public_body) do
      FactoryBot.create(:public_body, name: "Test's Authority <b>test</b>")
    end

    it 'does not HTML escape the apostrophe in the request form' do
      using_session(user_session) do
        visit show_public_body_path(:url_name => public_body.url_name)
        click_link("Make a request to this authority")

        expect(page).not_to have_content "Test&#39;s Authority"
        expect(page).to have_content "Dear Test's Authority"
      end
    end

    it 'appends the user name' do
      using_session(user_session) do
        visit show_public_body_path(:url_name => public_body.url_name)
        click_link("Make a request to this authority")

        expect(page.source).
          to include("Yours faithfully,\n\n#{user.name}")
      end
    end

    it 'handles other special characters correctly' do
      public_body.update_attribute(:name, 'Test ("special" chars)')
      using_session(user_session) do
        visit show_public_body_path(:url_name => public_body.url_name)
        click_link("Make a request to this authority")

        expect(page).to have_content 'Dear Test ("special" chars)'
      end
    end

    it 'does not render authority name HTML on the preview page' do
      public_body.update_attribute(:name, "Test's <sup>html</sup> authority")
      using_session(user_session) do
        visit show_public_body_path(:url_name => public_body.url_name)
        click_link("Make a request to this authority")
        fill_in 'Summary', :with => "HTML test"
        find_button('Preview your public request').click

        expect(page).to have_content("Dear Test's <sup>html</sup> authority")
      end
    end

  end

end

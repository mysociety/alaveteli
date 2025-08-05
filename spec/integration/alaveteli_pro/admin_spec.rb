# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'integration/alaveteli_dsl'

describe "administering requests" do

  before do
    get_fixtures_xapian_index
  end

  context 'when the admin user is a pro' do
    let!(:pro_admin_user) do
      pro_user = FactoryBot.create(:pro_user)
      pro_user.add_role :admin
      pro_user
    end
    let!(:pro_admin_user_session) { login(pro_admin_user) }

    context 'when the user being administered is not a pro' do
      let!(:public_body) do
        FactoryBot.create(:public_body,
                          :name => 'example')
      end

      before do
        update_xapian_index
      end

      context "the admin user visits the non admin user's confirmation link" do
        it 'confirms the request' do
          post_redirect = create_request_and_user(public_body)

          using_pro_session(pro_admin_user_session) do
            visit confirm_path(:email_token => post_redirect.email_token)
            expect(current_url).to match(%r(/request/(.+)))
            current_url =~ %r(/request/(.+))
            url_title = $1
            info_request = InfoRequest.find_by_url_title(url_title)
            expect(info_request).not_to be_nil
          end
        end
      end

    end

  end

end

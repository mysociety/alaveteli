# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'request/_sidebar.html.erb' do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:track_thing) do
    FactoryBot.create(:track_thing, info_request: info_request)
  end
  let(:public_body) { info_request.public_body }
  let(:user) { info_request.user }
  let(:admin_user) { FactoryBot.create("admin_user") }

  def render_page
    assign :info_request, info_request
    assign :track_thing, track_thing
    assign :status, info_request.calculate_status
    assign :similar_requests, double.as_null_object
    assign :similar_more, double.as_null_object
    render
  end

  context "when the request has been reported" do
    before :each do
      info_request.report!("", "", nil)
    end

    context "and the request is hidden" do
      it "tell admins it's hidden" do
        info_request.prominence = "hidden"
        assign :user, admin_user
        render_page
        expect(response).to have_content("This request has prominence " \
                                         "'hidden'. You can only see it " \
                                         "because you are logged in as a " \
                                         "super user.")
      end
    end

    context "and the request is requester only" do
      it "should tell the user that only they can see it" do
        info_request.prominence = "requester_only"
        assign :user, user
        render_page
        expect(response).to have_content("This request is hidden, so that " \
                                         "only you the requester can see " \
                                         "it. Please contact us if you are " \
                                         "not sure why.")
      end
    end

    context "and then deemed okay and left to complete" do
      it "should let the user know that the admins have not hidden it" do
        info_request.set_described_state("successful")
        render_page
        expect(response).to have_content("This request has been marked for " \
                                         "review by the site " \
                                         "administrators, who have not " \
                                         "hidden it at this time.")
      end
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

describe "viewing requests in alaveteli_pro" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }
  let!(:embargo) { FactoryGirl.create(:embargo, info_request: info_request) }
  let!(:pro_user_session) { login(pro_user) }

  it "allows us to view a pro request" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      expect(page).to have_content(info_request.title)
    end
  end

  it "allows the user to extend an embargo" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      old_publish_at = embargo.publish_at
      expect(page).to have_content("This request is embargoed until " \
                                   "#{old_publish_at.to_date}")
      select "3 Months", from: "Extend embargo:"
      click_button("Extend")
      expected_publish_at = old_publish_at + 3.months
      expect(embargo.reload.publish_at).to eq(expected_publish_at)
      expect(page).to have_content("This request is embargoed until " \
                                   "#{expected_publish_at.to_date} ")
    end
  end

  it "allows the user to publish a request" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      old_publish_at = embargo.publish_at
      expect(page).to have_content("This request is embargoed until " \
                                   "#{old_publish_at.to_date}")
      click_button("Publish request")
      expect(info_request.reload.embargo).to be nil
      expect(page).to have_content("Your request is now public!")
    end
  end

  xit "allows the user to add an annotation" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      click_link("Add an annotation")
      # TODO - currently fails because the request is embargoed, and so the
      # comment controller returns a 404 for it.
      expect(page).to have_content "Add an annotation to #{info_request.title}"
      fill_in("comment_body", with: "Testing annotations")
      click_button("Preview your annotation")
      click_button("Post annotation")
      expect(page).to have_content("#{pro_user.name} left an annotation")
      expect(page).to have_content("Testing annotations")
    end
  end

  xit "allows the user to send a follow up" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      click_link("Send follow up")
      expect(page).to have_content "Send a public follow up message to the " \
                                   "main FOI contact at " \
                                   "#{info_request.public_body.name}"
      fill_in("outgoing_message_body", with: "Testing follow ups")
      choose("Anything else, such as clarifying, prompting, thanking")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing follow ups")
    end
  end

  xit "allows the user to write a reply" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      click_link("Write a reply")
      expect(page).to have_content "Send a public reply to the " \
                                   "main FOI contact at " \
                                   "#{info_request.public_body.name}"
      fill_in("outgoing_message_body", with: "Testing replies")
      choose("Anything else, such as clarifying, prompting, thanking")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing replies")
    end
  end

  xit "allows the user to download the entire request" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      click_link("Download a zip file of all correspondence")
      page.response_headers["Content-Disposition"].should == "attachment"
    end
  end

  xit "allows the user to request an internal review" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      click_link("Request an internal review")
      expect(page).to have_content "Request an internal review from " \
                                   "the main FOI contact at " \
                                   "#{info_request.public_body.name}"
      fill_in("outgoing_message_body", with: "Testing internal reviews")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing internal reviews")
    end
  end

  it "allows the user to update the request status" do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      expect(page).to have_content("Update status")
      expect(find_field("Waiting for a response")).to be_checked
      choose("Partially successful")
      click_button("Update")
      expect(info_request.reload.described_state).to eq ("partially_successful")
      expect(page).to have_content("Your request has been updated!")
      # The form should still be there to allow us to go back if we updated
      # by mistake
      expect(page).to have_content("Update status")
      expect(find_field("Partially successful")).to be_checked
    end
  end
end

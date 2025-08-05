# -*- encoding : utf-8 -*-
shared_examples_for 'allows the embargo to be lifted' do

  it 'allows the user to publish a request' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      old_publish_at = embargo.publish_at.strftime('%-d %B %Y')
      expect(page).to have_content("private until #{old_publish_at}")
      click_button("Publish request")
      expect(info_request.reload.embargo).to be nil
      expect(page).to have_content(/Your requests? (is|are) now public!/)
    end
  end

end

shared_examples_for 'allows annotations' do

  it 'allows the user to add an annotation' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      first(:link, 'Add an annotation').click
      expect(page).
        to have_content "Add an annotation to “#{info_request.title}”"
      fill_in("comment_body", with: "Testing annotations")
      click_button("Preview your annotation")
      click_button("Post annotation")
      expect(page).to have_content("#{pro_user.name} left an annotation")
      expect(page).to have_content("Testing annotations")
    end
  end

end

shared_examples_for 'allows followups' do

  it 'allows the user to send a follow up' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      first(:link, 'Send a followup').click
      expect(page).to have_content "Send a follow up message to the " \
                                   "main FOI contact at " \
                                   "#{info_request.public_body.name}"
      fill_in("outgoing_message_body", with: "Testing follow ups")
      choose("Anything else, such as clarifying, prompting, thanking")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing follow ups")
    end
  end

end

shared_examples_for 'prevents setting an embargo' do

  it 'does not show the option to add an embargo' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      expect(page).not_to have_content "Keep private for"
    end
  end

end

shared_examples_for 'a request with response' do

  before do
    incoming_message = FactoryBot.create(:plain_incoming_message,
                                         :info_request => info_request)
    info_request.log_event("response",
                           {:incoming_message_id => incoming_message.id})
  end

  it 'allows the user to write a reply' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      first(:link, "Write a reply").click
      expect(page).to have_content "Send a reply to"
      fill_in("outgoing_message_body", with: "Testing replies")
      choose("Anything else, such as clarifying, prompting, thanking")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing replies")
    end
  end

  it 'allows the user to download the entire request' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      first(:link, "Download a zip file of all correspondence").click
      expected = /attachment; filename="example_title_.*\.zip"/
      expect(page.response_headers["Content-Disposition"]).
        to match(expected)
    end
  end

  it 'allows the user to request an internal review' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      first(:link, "Request an internal review").click
      expect(page).to have_content "Request an internal review from " \
                                   "the main FOI contact at " \
                                   "#{info_request.public_body.name}"
      fill_in("outgoing_message_body", with: "Testing internal reviews")
      click_button("Preview your message")
      click_button("Send message")
      expect(page).to have_content("Testing internal reviews")
    end
  end

  it 'allows the user to update the request status' do
    using_pro_session(pro_user_session) do
      browse_pro_request(info_request.url_title)
      expect(page).to have_content("Status")
      check 'Change status'
      # The current status shouldn't be checked, so that you can set it
      # again if you need too, e.g. to reset the awaiting response status
      expect(find_field("Awaiting response")).not_to be_checked
      choose("Partially successful")
      within ".update-status" do
        click_button("Update")
      end
      expect(info_request.reload.described_state).
        to eq ("partially_successful")
      expect(page).to have_content("Your request has been updated!")
      # The form should still be there to allow us to go back if we
      # updated by mistake
      expect(page).to have_content("Status")
      check 'Change status'
    end
  end

end

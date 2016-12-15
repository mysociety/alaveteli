# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

describe "creating requests in alaveteli_pro" do
  context "when writing a new request from scratch" do
    let!(:public_body) { FactoryGirl.create(:public_body) }
    let!(:pro_user) { FactoryGirl.create(:pro_user) }
    let!(:pro_user_session) { login(pro_user) }

    it "allows us to save a draft" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        fill_in "Summary", with: "Does the pro request form work?"
        fill_in "Your request", with: "A very short letter."
        select "3 Months", from: "Embargo"
        click_button "Save draft"

        # Redirected back to new request form
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist
        draft = drafts.first
        expect(draft.body).to eq "A very short letter."
        expect(draft.embargo_duration).to eq "3_months"

        expect(page).to have_content("Your draft has been saved!")
        expect(page).to have_content("This request will be embargoed " \
                                     "until #{Time.zone.today + 3.months}")

        # The page should pre-fill the form with data from the draft
        expect(page).to have_select("To", selected: public_body.name)
        expect(page).to have_field("Summary",
                                   with: "Does the pro request form work?")
        expect(page).to have_field("Your request",
                                   with: "A very short letter.")
        expect(page).to have_select("Embargo", selected: "3 Months")
      end
    end

    it "allows us to preview the request" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        fill_in "Summary", with: "Does the pro request form work?"
        fill_in "Your request", with: "A very short letter."
        select "3 Months", from: "Embargo"
        click_button "Preview and send"

        # Preview page
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist

        expect(page).to have_content("Preview your request")
        # The fact there's a draft should be hidden from the user
        expect(page).not_to have_content("Your draft has been saved!")

        expect(page).to have_content("To #{public_body.name}")
        expect(page).to have_content("Subject Does the pro request form " \
                                     "work?")
        expect(page).to have_content("A very short letter.")
        expect(page).to have_content("This request will be embargoed " \
                                     "until #{Time.zone.today + 3.months}")
      end
    end

    it "allows us to send the request" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        fill_in "Summary", with: "Does the pro request form work?"
        fill_in "Your request", with: "A very short letter."
        select "3 Months", from: "Embargo"
        click_button "Preview and send"

        # Preview page
        click_button "Send request"

        # Request page
        expect(page).to have_selector("h1", text: "Does the pro request form work?")

        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).not_to exist

        info_requests = InfoRequest.where(title: "Does the pro request form work?")
        expect(info_requests).to exist

        info_request = info_requests.first

        embargo = info_request.embargo
        expect(embargo).not_to be_nil
        expect(embargo.publish_at).to eq Time.zone.today + 3.months

        expect(info_request.outgoing_messages.length).to eq 1
        expect(info_request.outgoing_messages.first.body).to eq "A very short letter."

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/A very short letter\./)
        expect(mail.subject).to match(/Freedom of Information request - Does the pro request form work\?/)
        expect(mail.to).to eq([public_body.request_email])
      end
    end

    it "allow us to edit a request after previewing" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        fill_in "Summary", with: "Does the pro request form work?"
        fill_in "Your request", with: "A very short letter."
        select "3 Months", from: "Embargo"
        click_button "Preview and send"

        # Preview page
        click_link "Edit your request"

        # New request form again
        # The page should pre-fill the form with data from the draft
        expect(page).to have_select("To", selected: public_body.name)
        expect(page).to have_field("Summary",
                                   with: "Does the pro request form work?")
        expect(page).to have_field("Your request",
                                   with: "A very short letter.")
        expect(page).to have_select("Embargo", selected: "3 Months")

        fill_in "Your request", with: "A very short letter, edited."
        click_button "Save draft"

        # Redirected back to new request form
        drafts = DraftInfoRequest.where(title: "Does the pro request form work?")
        expect(drafts).to exist
        draft = drafts.first
        expect(draft.body).to eq "A very short letter, edited."
        expect(draft.embargo_duration).to eq "3_months"

        expect(page).to have_content("Your draft has been saved!")

        click_button "Preview and send"

        # Preview page again
        expect(page).to have_content("Preview your request")
        # The fact there's a draft should be hidden from the user
        expect(page).not_to have_content("Your draft has been saved!")

        expect(page).to have_content("To #{public_body.name}")
        expect(page).to have_content("Subject Does the pro request form " \
                                     "work?")
        expect(page).to have_content("A very short letter, edited.")
        expect(page).to have_content("This request will be embargoed " \
                                     "until #{Time.zone.today + 3.months}")
      end
    end

    it "shows errors if we leave fields blank" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        click_button "Preview and send"

        # New request form with errors
        expect(page).to have_content "Please enter a summary of your " \
                                     "request"
        expect(page).to have_content 'Please sign at the bottom with ' \
                                     'your name, or alter the "Yours ' \
                                     'faithfully," signature'
      end
    end

    it "saves the draft even if we leave fields blank" do
      using_pro_session(pro_user_session) do
        # New request form
        visit new_alaveteli_pro_info_request_path
        expect(page).to have_content "Make a request"
        select public_body.name, from: "To"
        click_button "Save draft"

        # New request form with errors
        expect(page).not_to have_content "Please enter a summary of your " \
                                         "request"
        expect(page).not_to have_content 'Please sign at the bottom with ' \
                                         'your name, or alter the "Yours ' \
                                         'faithfully," signature'
      end
    end
  end
end

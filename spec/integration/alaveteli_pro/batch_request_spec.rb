# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

def start_batch_request
  visit(new_alaveteli_pro_batch_request_authority_search_path)

  # Add some bodies to the batch
  fill_in "Search for an authority by name", with: "Example"
  click_button "Search"
  add_body_to_pro_batch(authorities[0])
  add_body_to_pro_batch(authorities[24])
  click_link "Next →"
  add_body_to_pro_batch(authorities[25])

  click_button "Write request"

  # Writing page
  expect(page).to have_content("3 recipients")
end

def fill_in_batch_message
  fill_in "Subject", with: "Does the pro batch request form work?"
  fill_in "Your request", with: "Dear [Authority name], this is a batch request."
  select "3 Months", from: "Privacy"
end

describe "creating batch requests in alaveteli_pro" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let!(:pro_user_session) { login(pro_user) }
  let!(:authorities) { FactoryGirl.create_list(:public_body, 26) }

  before :all do
    get_fixtures_xapian_index
  end

  before do
    update_xapian_index
  end

  after do
    authorities.each do |authority|
      authority.destroy
    end
    update_xapian_index
  end

  it "allows the user to build a list of authorities" do
    using_pro_session(pro_user_session) do
      visit(new_alaveteli_pro_batch_request_authority_search_path)

      # Searching
      fill_in "Search for an authority by name", with: "Example"
      click_button "Search"
      expect(page).to have_text(authorities[0].name)
      expect(page).to have_text(authorities[24].name)
      expect(page).not_to have_text(authorities[25].name)

      # Paginating
      click_link "Next →"
      expect(page).not_to have_text(authorities[24].name)
      expect(page).to have_text(authorities[25].name)

      click_link "← Previous"
      expect(page).to have_text(authorities[0].name)
      expect(page).to have_text(authorities[24].name)
      expect(page).not_to have_text(authorities[25].name)

      # Adding to list
      add_body_to_pro_batch(authorities[0])
      add_body_to_pro_batch(authorities[24])
      within ".batch-builder__chosen-authorities" do
        expect(page).to have_text(authorities[0].name)
        expect(page).to have_text(authorities[24].name)
      end

      within ".batch-builder__search-results li[data-body-id=\"#{authorities[0].id}\"]" do
        # The "Added" text is always there, so we have to test explicitly
        # that it's visible
        expect(page).to have_css("span", text: "Added", visible: true)
      end
      within ".batch-builder__search-results li[data-body-id=\"#{authorities[24].id}\"]" do
        # The "Added" text is always there, so we have to test explicitly
        # that it's visible
        expect(page).to have_css("span", text: "Added", visible: true)
      end

      # Removing from list
      within ".batch-builder__chosen-authorities form[data-body-id=\"#{authorities[0].id}\"]" do
        click_button "- Remove"
      end

      within ".batch-builder__chosen-authorities" do
        expect(page).not_to have_text(authorities[0].name)
      end
    end
  end

  it "allows the user to save a draft of a message" do
    using_pro_session(pro_user_session) do
      start_batch_request

      fill_in_batch_message

      click_button "Save draft"

      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(drafts).to exist
      draft = drafts.first
      expect(draft.body).to eq "Dear [Authority name], this is a batch request."
      expect(draft.embargo_duration).to eq "3_months"
      expect(draft.public_bodies).to eq [authorities[0], authorities[24], authorities[25]]

      expect(page).to have_content("Your draft has been saved!")
      expect(page).to have_content("This request will be private on " \
                                   "Alaveteli until " \
                                   "#{AlaveteliPro::Embargo.three_months_from_now.strftime('%d %B %Y')}")

      # The page should pre-fill the form with data from the draft
      expect(page).to have_field("Subject",
                                 with: "Does the pro batch request form work?")
      expect(page).to have_field("Your request",
                                 with: "Dear [Authority name], this is a batch request.")
      expect(page).to have_select("Privacy", selected: "3 Months")
    end
  end

  it "allows the user to save a draft of a message with no embargo" do
    using_pro_session(pro_user_session) do
      start_batch_request

      fill_in_batch_message
      select "Publish immediately", from: "Privacy"

      click_button "Save draft"

      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(drafts).to exist
      draft = drafts.first
      expect(draft.embargo_duration).to eq ""

      expect(page).to have_select("Privacy", selected: "Publish immediately")

      expect(page).to have_content("Unless you choose a privacy option, your " \
                                   "request will be public on Alaveteli " \
                                   "immediately.")
    end
  end

  it "allows the user to go back and edit the bodies in the batch" do
    using_pro_session(pro_user_session) do
      start_batch_request

      click_link "show all"

      # Search page
      fill_in "Search for an authority by name", with: "Example"
      click_button "Search"

      add_body_to_pro_batch(authorities[1])
      within ".batch-builder__chosen-authorities" do
        expect(page).to have_text(authorities[1].name)
      end
      within ".batch-builder__search-results li[data-body-id=\"#{authorities[1].id}\"]" do
        # The "Added" text is always there, so we have to test explicitly
        # that it's visible
        expect(page).to have_css("span", text: "Added", visible: true)
      end

      click_button "Write request"

      # Write page
      expect(page).to have_content("4 recipients")
    end
  end

  it "allows the user to preview a message before sending" do
    using_pro_session(pro_user_session) do
      start_batch_request
      fill_in_batch_message
      click_button "Preview and send request"

      # Preview page
      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(drafts).to exist
      draft = drafts.first

      expect(page).to have_content("Preview new batch request")
      # The fact there's a draft should be hidden from the user
      expect(page).not_to have_content("Your draft has been saved!")

      expect(page).to have_content("3 recipients")
      expect(page).to have_content("Subject Does the pro batch request " \
                                   "form work?")
      # It should substitue an authority name in when previewing
      first_authority = draft.public_bodies.first
      expect(page).to have_content("Dear #{first_authority.name}, this is a batch request.")
      expect(page).to have_content("This request will be private on " \
                                   "Alaveteli until " \
                                   "#{AlaveteliPro::Embargo.three_months_from_now.strftime('%d %B %Y')}")

    end
  end

  it "allows the user to edit a message after previewing it" do
    using_pro_session(pro_user_session) do
      start_batch_request
      fill_in_batch_message
      click_button "Preview and send request"
      click_link "Edit your request"
      fill_in "Subject", with: "Edited title"
      click_button "Save draft"

      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Edited title")
      expect(drafts).to exist
    end
  end

  it "shows errors if the user tries to preview with fields left blank" do
    using_pro_session(pro_user_session) do
      start_batch_request
      click_button "Preview and send request"
      expect(page).to have_content("Please enter a summary of your request")
      expect(page).to have_content("Please enter your letter requesting information")
    end
  end

  it "allows the user to save a draft even with fields left blank" do
    using_pro_session(pro_user_session) do
      start_batch_request
      fill_in "Subject", with: ""
      fill_in "Your request", with: ""
      select "Publish immediately", from: "Privacy"
      click_button "Save draft"

      expect(page).to have_content("Your draft has been saved!")
      expect(page).to have_content("Unless you choose a privacy option, your " \
                                   "request will be public on Alaveteli " \
                                   "immediately.")

      # The page should pre-fill the form with data from the draft
      expect(page).to have_field("Subject",
                                 with: "")
      expect(page).to have_field("Your request",
                                 with: "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}")
      expect(page).to have_select("Privacy", selected: "Publish immediately")

    end
  end

  it "provides a template for the users request" do
    using_pro_session(pro_user_session) do
      start_batch_request
      expect(page).to have_field("Your request",
                                 with: "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}")
    end
  end

  it "allows the user to create a batch request" do
    using_pro_session(pro_user_session) do
      start_batch_request
      fill_in_batch_message
      click_button "Preview and send request"
      click_button "Send 3 requests"

      expect(page).to have_content("Does the pro batch request form work? " \
                                   "- a batch request")
      expect(page).to have_content("Requests will be sent to the following bodies:")
      expect(page).to have_content(authorities[0].name)
      expect(page).to have_content(authorities[24].name)
      expect(page).to have_content(authorities[25].name)

      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(drafts).not_to exist

      batches = InfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(batches).to exist
      batch = batches.first

      expect(batch.body).to eq "Dear [Authority name], this is a batch request."
      expect(batch.embargo_duration).to eq "3_months"
      expect(batch.public_bodies).
        to match_array [authorities[0], authorities[24], authorities[25]]
    end
  end
end

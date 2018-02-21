# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

def start_batch_request
  visit(alaveteli_pro_batch_request_authority_searches_path)

  # Add some bodies to the batch
  fill_in "Search for an authority by name", with: "Example"
  click_button "Search"
  # We can't rely on Xapina to give us a deterministic search result ordering
  # so we pluck some bodies out of the results we see
  first_page_results = search_results
  first_search_result_body = PublicBody.find_by(name: first_page_results.first)
  last_search_result_body = PublicBody.find_by(name: first_page_results.last)
  add_body_to_pro_batch(first_search_result_body)
  add_body_to_pro_batch(last_search_result_body)
  click_link "Next →"
  second_page_result = search_results.first
  second_page_search_result_body = PublicBody.find_by(name: second_page_result)
  add_body_to_pro_batch(second_page_search_result_body)

  @selected_bodies = [
    first_search_result_body,
    last_search_result_body,
    second_page_search_result_body
  ]

  click_button "Write request"

  # Writing page
  expect(page).to have_content("3 recipients")
end

def fill_in_batch_message
  fill_in "Subject", with: "Does the pro batch request form work?"
  fill_in "Your request", with: "Dear [Authority name], this is a batch request."
end

def search_results
  page.find_all(".batch-builder__authority-list__authority__name").map(&:text)
end

describe "creating batch requests in alaveteli_pro" do
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

  let(:pro_user) do
    user = FactoryGirl.create(:pro_user)
    AlaveteliFeatures.backend.enable_actor(:pro_batch_access, user)
    FactoryGirl.create(:pro_account,
                       user: user,
                       stripe_customer_id: 'test_customer',
                       monthly_batch_limit: 25)
    user
  end

  let!(:pro_user_session) { login(pro_user) }

  it "allows the user to build a list of authorities" do
    using_pro_session(pro_user_session) do
      visit(alaveteli_pro_batch_request_authority_searches_path)

      # Searching
      fill_in "Search for an authority by name", with: "Example"
      click_button "Search"

      expect(page).to have_css(".batch-builder__authority-list__authority", count: 25)
      first_page_results = search_results

      # Paginating
      click_link "Next →"

      expect(page).to have_css(".batch-builder__authority-list__authority", count: 1)
      second_page_result = search_results.first

      # We can't rely on Xapian to give us a deterministic search result
      # ordering so we just compare the results on each page to make sure
      # they're different
      expect(first_page_results.include?(second_page_result)).to be false

      click_link "← Previous"
      expect(page).to have_css(".batch-builder__authority-list__authority", count: 25)
      first_page_results = search_results

      expect(first_page_results.include?(second_page_result)).to be false


      # Adding to list
      # We can't rely on Xapian to give us a deterministic search result
      # ordering so we pluck some bodies out of the results we see
      first_search_result_body = PublicBody.find_by(name: search_results.first)
      last_search_result_body = PublicBody.find_by(name: search_results.last)
      add_body_to_pro_batch(first_search_result_body)
      add_body_to_pro_batch(last_search_result_body)
      within ".batch-builder__chosen-authorities" do
        expect(page).to have_text(first_search_result_body.name)
        expect(page).to have_text(last_search_result_body.name)
      end

      within ".batch-builder__search-results li[data-body-id=\"#{first_search_result_body.id}\"]" do
        # The "Added" text is always there, so we have to test explicitly
        # that it's visible
        expect(page).to have_css("span", text: "Added", visible: true)
      end
      within ".batch-builder__search-results li[data-body-id=\"#{last_search_result_body.id}\"]" do
        # The "Added" text is always there, so we have to test explicitly
        # that it's visible
        expect(page).to have_css("span", text: "Added", visible: true)
      end

      # Removing from list
      within ".batch-builder__chosen-authorities form[data-body-id=\"#{first_search_result_body.id}\"]" do
        click_button "- Remove"
      end

      within ".batch-builder__chosen-authorities" do
        expect(page).not_to have_text(first_search_result_body.name)
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
      expect(draft.public_bodies).to match_array(@selected_bodies)

      expect(page).to have_content("Your draft has been saved!")
      expect(page).to have_content(
        "Requests in this batch will be private on Alaveteli until " \
        "#{AlaveteliPro::Embargo.three_months_from_now.strftime('%-d %B %Y')}")

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

      expect(page).to have_content("Unless you choose a privacy option, " \
                                   "requests in this batch will be public " \
                                   "on Alaveteli immediately.")
    end
  end

  it "allows the user to go back and edit the bodies in the batch" do
    using_pro_session(pro_user_session) do
      start_batch_request

      click_link "show all"

      # Search page
      fill_in "Search for an authority by name", with: "Example"
      click_button "Search"

      second_search_result_body = PublicBody.find_by(name: search_results.second)
      add_body_to_pro_batch(second_search_result_body)
      within ".batch-builder__chosen-authorities" do
        expect(page).to have_text(second_search_result_body.name)
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
      expect(page).to have_content(
        "Requests in this batch will be private on Alaveteli until " \
        "#{AlaveteliPro::Embargo.three_months_from_now.strftime('%-d %B %Y')}")

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
      click_button "Save draft"

      expect(page).to have_content("Your draft has been saved!")

      # The page should pre-fill the form with data from the draft
      expect(page).to have_field("Subject",
                                 with: "")
      expect(page).to have_field("Your request",
                                 with: "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}")
    end
  end

  it "provides a template for the users request" do
    using_pro_session(pro_user_session) do
      start_batch_request
      expect(page).to have_field("Your request",
                                 with: "Dear [Authority name],\n\n\n\nYours faithfully,\n\n#{pro_user.name}")
    end
  end

  it "supplies a default embargo when creating a new batch request" do
    using_pro_session(pro_user_session) do
      start_batch_request
       expect(page).to have_select("Privacy", selected: "3 Months")
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
      @selected_bodies.each do |body|
        expect(page).to have_content(body.name)
        expect(page).to have_content(body.name)
        expect(page).to have_content(body.name)
      end

      drafts = AlaveteliPro::DraftInfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(drafts).not_to exist

      batches = InfoRequestBatch.where(title: "Does the pro batch request form work?")
      expect(batches).to exist
      batch = batches.first

      expect(batch.body).to eq "Dear [Authority name], this is a batch request."
      expect(batch.embargo_duration).to eq "3_months"
      expect(batch.public_bodies).to match_array @selected_bodies
    end
  end

  context 'the user has exceeded their batch limit' do

    before { pro_user.pro_account.update_attributes(monthly_batch_limit: 0) }

    let(:batch) do
      FactoryGirl.create(:draft_info_request_batch,
                         user: pro_user,
                         public_bodies: [FactoryGirl.create(:public_body)],
                         title: 'Test Batch')
    end

    it 'allows the user to edit an existing draft batch request' do
      using_pro_session(pro_user_session) do
        visit new_alaveteli_pro_info_request_batch_path(draft_id: batch.id)
        fill_in 'Subject', with: 'Edited title'
        click_button 'Save draft'

        expect(batch.reload.title).to eq('Edited title')
      end
    end

    it 'does not show the "Preview and send" button' do
      using_pro_session(pro_user_session) do
        visit new_alaveteli_pro_info_request_batch_path(draft_id: batch.id)

        expect(page).not_to have_content("Preview and send request")
      end
    end

  end

end

describe "managing embargoed batch requests" do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let!(:pro_user_session) { login(pro_user) }
  let!(:batch) do
    batch = FactoryGirl.create(
      :embargoed_batch_request,
      user: pro_user,
      public_bodies: FactoryGirl.create_list(:public_body, 2))
    batch.create_batch!
    batch
  end

  describe "managing embargoes on a batch request's page" do

    it "allows the user to extend all the embargoes that are near expiry" do
      batch.info_requests.each do |info_request|
        info_request.
          embargo.
            update_attribute(:publish_at,
                             info_request.embargo.publish_at - 88.days)
      end
      batch.reload

      using_pro_session(pro_user_session) do
        visit show_alaveteli_pro_batch_request_path(batch)
        old_publish_at = batch.info_requests.first.embargo.publish_at

        check 'Change privacy'
        expect(page).to have_content("Requests in this batch are private on " \
                                     "Alaveteli until " \
                                     "#{old_publish_at.strftime('%-d %B %Y')}")
        select "3 Months", from: "Keep private for a further:"
        within ".update-embargo" do
          click_button("Update")
        end

        check 'Change privacy'
        expected_publish_at = old_publish_at + \
                              AlaveteliPro::Embargo::THREE_MONTHS
        expected_content = "Requests in this batch are private on Alaveteli " \
                           "until #{expected_publish_at.strftime('%-d %B %Y')}"
        expect(page).to have_content(expected_content)

        batch.info_requests.each do |info_request|
          expect(info_request.embargo.publish_at).to eq expected_publish_at
        end
      end
    end

    it "allows the user to publish all the requests" do
      using_pro_session(pro_user_session) do
        visit show_alaveteli_pro_batch_request_path(batch)
        old_publish_at = batch.info_requests.first.embargo.publish_at

        check 'Change privacy'
        expect(page).to have_content(
          "Requests in this batch are private on Alaveteli until " \
          "#{old_publish_at.strftime('%-d %B %Y')}")
        click_button("Publish requests")
        expect(batch.reload.embargo_duration).to be nil
        batch.info_requests.each do |info_request|
          expect(info_request.embargo).to be_nil
        end
        expect(page).to have_content("Your requests are now public!")
      end
    end
  end

  describe "managing embargoes on a specific request in a batch" do
    let(:info_request) { batch.info_requests.first }

    it "allows the user to extend all expiring embargoes from a specific request" do
      batch.info_requests.each do |info_request|
        info_request.
          embargo.
            update_attribute(:publish_at,
                             info_request.embargo.publish_at - 88.days)
      end
      batch.reload

      using_pro_session(pro_user_session) do
        browse_pro_request(info_request.url_title)
        old_publish_at = info_request.embargo.publish_at
        expect(page).to have_content(
          "Requests in this batch are private on Alaveteli until " \
          "#{old_publish_at.strftime('%-d %B %Y')}")
        select "3 Months", from: "Keep private for a further:"
        within ".update-embargo" do
          click_button("Update")
        end
        expected_publish_at = old_publish_at + \
                              AlaveteliPro::Embargo::THREE_MONTHS
        expect(page).to have_content(
          "Requests in this batch are private on Alaveteli until " \
          "#{expected_publish_at.strftime('%-d %B %Y')}")
        batch.info_requests.each do |info_request|
          expect(info_request.embargo.publish_at).to eq expected_publish_at
        end
      end
    end

    it "allows the user to publish a request" do
      using_pro_session(pro_user_session) do
        browse_pro_request(info_request.url_title)
        old_publish_at = info_request.embargo.publish_at
        expect(page).to have_content("Requests in this batch are private on " \
                                     "Alaveteli until " \
                                     "#{old_publish_at.strftime('%-d %B %Y')}")
        click_button("Publish request")
        batch.info_requests.each do |info_request|
          expect(info_request.embargo).to be_nil
        end
        expect(page).to have_content("Your requests are now public!")
      end
    end
  end
end

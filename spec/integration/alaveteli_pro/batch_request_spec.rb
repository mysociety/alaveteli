# -*- encoding : utf-8 -*-
require 'spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../alaveteli_dsl')

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
      within ".batch-builder__search-results li[data-body-id=\"#{authorities[0].id}\"]" do
        click_button "+ Add"
      end
      within ".batch-builder__search-results li[data-body-id=\"#{authorities[24].id}\"]" do
        click_button "+ Add"
      end

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
end

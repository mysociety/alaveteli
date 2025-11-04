require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe RequestController do
  describe 'when the site is in read only mode' do
    before do
      allow(AlaveteliConfiguration).to receive(:read_only).
        and_return("Down for maintenance")
    end

    it 'shows a flash alert to users' do
      expected_message = "Alaveteli is currently in maintenance. " \
                         "Down for maintenance"
      visit new_request_path
      expect(page).to have_content(expected_message)
    end
  end

  describe 'when requests feature is in read only mode' do
    before do
      allow(AlaveteliConfiguration).to receive(:read_only_features).
        and_return(["requests"])
    end

    it 'shows a flash alert to users' do
      expected_message = "Alaveteli is currently in maintenance."
      visit new_request_path
      expect(page).to have_content(expected_message)
    end
  end

  describe 'FOI officer uploading a response' do
    let(:public_body) do
      FactoryBot.create(:public_body, request_email: "foi@example.com")
    end
    let(:officer) { FactoryBot.create(:user, email: "officer@example.com") }
    let(:user) { FactoryBot.create(:user, name: "Awkward > Name") }
    let(:request) { FactoryBot.create(:info_request, user: user) }

    it 'should render a message confirming the response has been published' do
      message = "Thank you for responding to this FOI request! " \
                "Your response has been published below, and a " \
                "link to your response has been emailed to Awkward > Name."
      using_session(login(officer)) do
        visit upload_response_path url_title: request.url_title
        fill_in(:body, with: 'Additional information')
        click_button("Upload FOI response")
        expect(page).to have_content(message)
      end
    end
  end

  it "should redirect from a numeric URL to pretty one" do
    visit show_request_path(info_requests(:naughty_chicken_request).id)
    expect(current_path).to eq(
      show_request_path(
        info_requests(:naughty_chicken_request).url_title
      )
    )
  end
end

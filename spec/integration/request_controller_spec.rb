# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe RequestController do

  describe 'when the site is in read only mode' do

    before do
      allow(AlaveteliConfiguration).to receive(:read_only).
        and_return("Down for maintenance")
    end

    it 'shows a flash alert to users' do
      expected_message = "Alaveteli is currently in maintenance. You " \
                         "can only view existing requests. You cannot " \
                         "make new ones, add followups or annotations, or " \
                         "otherwise change the database." \
                         "\nDown for maintenance"

      expected_message.gsub!("\n", ' ') unless rails5?

      visit new_request_path
      expect(page).to have_content(expected_message)
    end

    context 'when annotations are disabled' do

      before do
        allow_any_instance_of(ApplicationController).
          to receive(:feature_enabled?).
            and_call_original

        allow_any_instance_of(ApplicationController).
          to receive(:feature_enabled?).
            with(:annotations).
              and_return(false)
      end

      it 'shows a flash alert to users' do
        expected_message = "Alaveteli is currently in maintenance. You " \
                           "can only view existing requests. You cannot make " \
                           "new ones, add followups or otherwise change the " \
                           "database.\nDown for maintenance"

        expected_message.gsub!("\n", ' ') unless rails5?

        visit new_request_path
        expect(page).to have_content(expected_message)
      end

    end

  end

  describe 'FOI officer uploading a reponse' do

    let(:public_body) do
      FactoryBot.create(:public_body, :request_email => "foi@example.com")
    end
    let(:officer) { FactoryBot.create(:user, :email => "officer@example.com") }
    let(:user) { FactoryBot.create(:user, :name => "Awkward > Name") }
    let(:request) { FactoryBot.create(:info_request, :user => user) }

    it 'should render a message confirming the response has been published' do
      message = "Thank you for responding to this FOI request! " \
                "Your response has been published below, and a " \
                "link to your response has been emailed to Awkward > Name."
      using_session(login(officer)) do
        visit upload_response_path :url_title => request.url_title
        fill_in(:body, :with => 'Additional information')
        click_button("Upload FOI response")
        expect(page).to have_content(message)
      end
    end

  end

end

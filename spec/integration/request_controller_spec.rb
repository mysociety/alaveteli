# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe RequestController, "when classifying an information request" do

  describe 'when the request is internal' do

    before(:each) do
      load_raw_emails_data
      @dog_request = info_requests(:fancy_dog_request)
      # This should happen automatically before each test but doesn't with these integration
      # tests for some reason.
      ActionMailer::Base.deliveries = []
    end

    describe 'when logged in as the requestor' do

      before :each do
        @bob = login(:bob_smith_user)
      end

      it "should send an email including the message" do
        using_session(@bob) do
          visit describe_state_message_path(:url_title => @dog_request.url_title,
                                            :described_state => "requires_admin")
          fill_in "Please tell us more:", :with => "Okay. I don't quite understand."
          click_button "Submit status and send message"
          expect(page).to have_content "Thank you! We'll look into what happened and try and fix it up."
        end

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/as needing admin/)
        expect(mail.body).to match(/Okay. I don't quite understand./)
      end
    end
  end

  describe 'when the site is in read only mode' do

    before do
      allow(AlaveteliConfiguration).to receive(:read_only).
        and_return("Down for maintenance")
    end

    it 'shows a flash alert to users' do
      expected_message = 'Alaveteli is currently in maintenance. You ' \
                         'can only view existing requests. You cannot make ' \
                         'new ones, add followups or annotations, or ' \
                         'otherwise change the database. '\
                         'Down for maintenance'

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
        expected_message = 'Alaveteli is currently in maintenance. You ' \
                           'can only view existing requests. You cannot make ' \
                           'new ones, add followups or otherwise change the ' \
                           'database. Down for maintenance'

        visit new_request_path
        expect(page).to have_content(expected_message)
      end

    end

  end

  describe 'FOI officer uploading a reponse' do

    let(:public_body) do
      FactoryGirl.create(:public_body, :request_email => "foi@example.com")
    end
    let(:officer) { FactoryGirl.create(:user, :email => "officer@example.com") }
    let(:user) { FactoryGirl.create(:user, :name => "Awkward > Name") }
    let(:request) { FactoryGirl.create(:info_request, :user => user) }

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

  describe 'request owner classifying a request' do

    let(:info_request) { FactoryGirl.create(:info_request) }
    let(:user) { info_request.user }

    context 'marking request as error_message' do

      let(:classification) { 'error_message1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)

          # fill in form on the next page to supply more info about the error
          fill_in 'incoming_message_message', :with => 'test data'
          click_button('Submit status and send message')

          message = "Thank you! We'll look into what happened " \
                    "and try and fix it up."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking request as internal_review' do

      let(:classification) { 'internal_review1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Thank you! Hopefully your wait isn't too long."
          # redirect and receive thank you message
          expect(page).to have_content(message)
          expect(page).to have_link('details',
                                    :href => unhappy_url(
                                              info_request,
                                              :anchor => 'internal_review'))
        end
      end

    end

    context 'marking request as not_held' do

      let(:classification) { 'not_held1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Thank you! Here are some ideas on what to do next"
          # redirect and receive thank you message
          expect(page).to have_content(message)
          expect(page).to have_link("how to complain",
                                    :href => unhappy_url(info_request))
        end
      end

    end

    context 'marking request as partially_successful' do

      let(:classification) { 'partially_successful1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "We're glad you got some of the information that you wanted"
          # redirect and receive thank you message
          expect(page).to have_content(message)
          expect(page).to_not have_link('make a donation')
        end
      end

      context 'there is a donation link' do

        it 'displays the donation link' do
          allow(AlaveteliConfiguration).to receive(:donation_url).
            and_return('http://donations.example.com')

          using_session(login(user)) do
            classify_request(info_request, classification)
            message = "We're glad you got some of the information that you wanted"
            # redirect and receive thank you message
            expect(page).to have_link('make a donation',
                                      :href => 'http://donations.example.com')
          end
        end
      end

    end

    context 'marking request as rejected' do

      let(:classification) { 'rejected1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Oh no! Sorry to hear that your request was refused"
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking request as requires_admin' do

      let(:classification) { 'requires_admin1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)

          # fill in form on the next page to supply more info about the error
          fill_in 'incoming_message_message', :with => 'test data'
          click_button('Submit status and send message')

          message = "Thank you! We'll look into what happened and try " \
                    "and fix it up."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking request as successful' do

      let(:classification) { 'successful1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)

          message = "We're glad you got all the information that you wanted. " \
                    "If you write about or make use of the information, " \
                    "please come back and add an annotation below saying " \
                    "what you did."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        expect(page).to_not have_link('make a donation')
        end
      end

      context 'there is a donation link' do

        it 'displays the donation link' do
          allow(AlaveteliConfiguration).to receive(:donation_url).
            and_return('http://donations.example.com')

          using_session(login(user)) do
            classify_request(info_request, classification)
            message = "We're glad you got some of the information " \
                      "that you wanted"
            # redirect and receive thank you message
            expect(page).to have_link('make a donation',
                                      :href => 'http://donations.example.com')
          end
        end

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

        it 'does not display the annotations part of the message' do

          using_session(login(user)) do
            classify_request(info_request, classification)
            message = "We're glad you got all the information that you wanted."
             unexpected = "please come back and add an annotation"
            # redirect and receive thank you message
            expect(page).to have_content(message)
            expect(page).to_not have_content(unexpected)
          end

        end

      end

    end

    context 'marking request as user_withdrawn' do

      let(:classification) { 'user_withdrawn1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "If you have not done so already, please write a " \
                    "message below telling the authority that you have " \
                    "withdrawn your request."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking request as waiting_clarification' do

      let(:classification) { 'waiting_clarification1' }

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Please write your follow up message containing the " \
                    "necessary clarifications below."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking request as waiting_response' do

      let(:classification) {'waiting_response1'}

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Thank you! Hopefully your wait isn't too long"
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking overdue request as waiting_response' do

      let(:classification) { 'waiting_response1' }

      before do
        time_travel_to(info_request.date_response_required_by + 2.days)
      end

      after do
        back_to_the_present
      end

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Thank you! Hope you don't have to wait much longer."
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

    context 'marking very overdue request as waiting_responses' do

      let(:classification) { 'waiting_response1' }

      before do
        time_travel_to(info_request.date_very_overdue_after + 2.days)
      end

      after do
        back_to_the_present
      end

      it 'displays a thank you message post redirect' do
        using_session(login(user)) do
          classify_request(info_request, classification)
          message = "Thank you! Your request is long overdue"
          # redirect and receive thank you message
          expect(page).to have_content(message)
        end
      end

    end

  end

end

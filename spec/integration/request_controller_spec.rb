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

end

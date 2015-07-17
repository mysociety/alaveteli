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
        @bob.visit describe_state_message_path(:url_title => @dog_request.url_title,
                                               :described_state => "requires_admin")
        @bob.fill_in "Please tell us more:", :with => "Okay. I don't quite understand."
        @bob.click_button "Submit status and send message"

        @bob.response.should contain "Thank you! We'll look into what happened and try and fix it up."

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /as needing admin/
        mail.body.should =~ /Okay. I don't quite understand./
      end
    end
  end
end

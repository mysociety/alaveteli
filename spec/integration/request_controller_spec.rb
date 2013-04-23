# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
                @request_owner = @dog_request.user
                visit signin_path
                fill_in "Your e-mail:", :with => @request_owner.email
                fill_in "Password:", :with => "jonespassword"
                click_button "Sign in"
            end

            it "should send an email including the message" do
                visit describe_state_message_path(:url_title => @dog_request.url_title,
                    :described_state => "requires_admin")
                fill_in "Please tell us more:", :with => "Okay. I don't quite understand."
                click_button "Submit status and send message"

                response.should contain "Thank you! We'll look into what happened and try and fix it up."

                deliveries = ActionMailer::Base.deliveries
                deliveries.size.should == 1
                mail = deliveries[0]
                mail.body.should =~ /as needing admin/
                mail.body.should =~ /Okay. I don't quite understand./                
            end
        end
    end
end

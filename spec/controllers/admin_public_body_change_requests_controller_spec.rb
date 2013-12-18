# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyChangeRequestsController, "editing a change request" do

    it "should render the edit template" do
        change_request = FactoryGirl.create(:add_body_request)
        get :edit, :id => change_request.id
        response.should render_template("edit")
    end

end

describe AdminPublicBodyChangeRequestsController, 'updating a change request' do

    before do
        @change_request = FactoryGirl.create(:add_body_request)
        post :update, { :id => @change_request.id,
                        :response => 'Thanks but no',
                        :subject => 'Your request' }
    end

    it 'should close the change request' do
        PublicBodyChangeRequest.find(@change_request.id).is_open.should == false
    end

    it 'should send a response email to the user who requested the change' do
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.subject.should == 'Your request'
        mail.to.should == [@change_request.get_user_email]
        mail.body.should =~ /Thanks but no/
    end
end

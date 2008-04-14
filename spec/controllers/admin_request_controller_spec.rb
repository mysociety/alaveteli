require File.dirname(__FILE__) + '/../spec_helper'

describe AdminRequestController, "when administering requests" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :users
  
    it "shows the index/list page" do
        get :index
    end

    it "shows a public body" do
        get :show, :id => info_requests(:fancy_dog_request)
    end

    it "edits a public body" do
        get :edit, :id => info_requests(:fancy_dog_request)
    end

    it "saves edits to a request" do
        info_requests(:fancy_dog_request).title.should == "Why do you have such a fancy dog?"
        post :update, { :id => info_requests(:fancy_dog_request), :info_request => { :title => "Renamed", :prominence => "normal", :described_state => "waiting_response", :awaiting_description => false } }
        response.flash[:notice].should include('successful')
        ir = InfoRequest.find(info_requests(:fancy_dog_request).id)
        ir.title.should == "Renamed"
    end

    it "edits an outgoing message" do
        get :edit_outgoing, :id => outgoing_messages(:useless_outgoing_message)
    end

    it "saves edits to an outgoing_message" do
        outgoing_messages(:useless_outgoing_message).body.should include("fancy dog")
        post :update_outgoing, { :id => outgoing_messages(:useless_outgoing_message), :outgoing_message => { :body => "Why do you have such a delicious cat?" } }
        response.flash[:notice].should include('successful')
        ir = OutgoingMessage.find(outgoing_messages(:useless_outgoing_message).id)
        ir.body.should include("delicious cat")
    end

end


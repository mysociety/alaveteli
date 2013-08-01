require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminOutgoingMessageController do
    render_views
    before { basic_auth_login @request }

    before(:each) do
        load_raw_emails_data
    end

    it "edits an outgoing message" do
        get :edit, :id => outgoing_messages(:useless_outgoing_message)
    end

    it "saves edits to an outgoing_message" do
        outgoing_messages(:useless_outgoing_message).body.should include("fancy dog")
        post :update, { :id => outgoing_messages(:useless_outgoing_message), :outgoing_message => { :body => "Why do you have such a delicious cat?" } }
        request.flash[:notice].should include('successful')
        ir = OutgoingMessage.find(outgoing_messages(:useless_outgoing_message).id)
        ir.body.should include("delicious cat")
    end

end

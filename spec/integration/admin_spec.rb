require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When administering the site" do

    before do
        AlaveteliConfiguration.stub!(:skip_admin_auth).and_return(false)
    end

    it "allows an admin to log in as another user" do
        # First log in as Joe Admin
        confirm(:admin_user)
        admin = login(:admin_user)

        # Now fetch the "log in as" link to log in as Bob
        admin.get_via_redirect "/en/admin/user/login_as/#{users(:bob_smith_user).id}"
        admin.response.should be_success
        admin.session[:user_id].should == users(:bob_smith_user).id
    end

    it 'does not allow a non-admin user to login as another user' do
        robin = login(:robin_user)
        robin.get_via_redirect "/en/admin/user/login_as/#{users(:bob_smith_user).id}"
        robin.response.should be_success
        robin.session[:user_id].should_not == users(:bob_smith_user).id
    end

    it "allows redelivery of an incoming message to a closed request" do
        confirm(:admin_user)
        admin = login(:admin_user)
        ir = info_requests(:fancy_dog_request)
        close_request(ir)
        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
        ir.incoming_messages.length.should == 1
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
        InfoRequest.holding_pen_request.incoming_messages.length.should == 1
        new_im = InfoRequest.holding_pen_request.incoming_messages[0]
        ir.incoming_messages.length.should == 1
        post_params = {'redeliver_incoming_message_id' => new_im.id,
                       'url_title' => ir.url_title}
        admin.post '/en/admin/incoming/redeliver', post_params
        admin.response.location.should == 'http://www.example.com/en/admin/request/show/101'
        ir = InfoRequest.find_by_url_title(ir.url_title)
        ir.incoming_messages.length.should == 2

        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
    end

    it "allows redelivery of an incoming message to more than one request" do
        confirm(:admin_user)
        admin = login(:admin_user)

        ir1 = info_requests(:fancy_dog_request)
        close_request(ir1)
        ir1.incoming_messages.length.should == 1
        ir2 = info_requests(:another_boring_request)
        ir2.incoming_messages.length.should == 1

        receive_incoming_mail('incoming-request-plain.email', ir1.incoming_email, "frob@nowhere.com")
        InfoRequest.holding_pen_request.incoming_messages.length.should == 1

        new_im = InfoRequest.holding_pen_request.incoming_messages[0]
        post_params = {'redeliver_incoming_message_id' => new_im.id,
                       'url_title' => "#{ir1.url_title},#{ir2.url_title}"}
        admin.post '/en/admin/incoming/redeliver', post_params
        ir1.reload
        ir1.incoming_messages.length.should == 2
        ir2.reload
        ir2.incoming_messages.length.should == 2
        admin.response.location.should == 'http://www.example.com/en/admin/request/show/106'
        InfoRequest.holding_pen_request.incoming_messages.length.should == 0
    end

end

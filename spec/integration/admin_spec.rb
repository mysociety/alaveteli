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
        admin.get_via_redirect "/admin/user/login_as/#{users(:bob_smith_user).id}"
        admin.response.should be_success
        admin.session[:user_id].should == users(:bob_smith_user).id
    end

    it 'does not allow a non-admin user to login as another user' do
        robin = login(:robin_user)
        robin.get_via_redirect "/admin/user/login_as/#{users(:bob_smith_user).id}"
        robin.response.should be_success
        robin.session[:user_id].should_not == users(:bob_smith_user).id
    end
end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController, "when making censor rules from the admin interface" do
    integrate_views
    before do
        basic_auth_login @request
        PurgeRequest.destroy_all
    end


    it "should create a censor rule and purge the corresponding request from varnish" do
        ir = info_requests(:fancy_dog_request)
        post :create, :censor_rule => {
                         :text => "meat",
                         :replacement => "tofu",
                         :last_edit_comment => "none",
                         :info_request => ir
        }
        PurgeRequest.all().first.model_id.should == ir.id
    end


end

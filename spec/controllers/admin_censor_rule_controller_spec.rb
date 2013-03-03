require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminCensorRuleController, "when making censor rules from the admin interface" do
    render_views
    before { basic_auth_login @request }
  
    it "should create a censor rule and purge the corresponding request from varnish" do
        ir = info_requests(:fancy_dog_request) 
        post :create, :censor_rule => {
                         :text => "meat",
                         :replacement => "tofu",
                         :last_edit_comment => "none",
                         :info_request_id => ir
        }
        PurgeRequest.all().first.model_id.should == ir.id
    end


end

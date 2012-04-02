require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When rendering errors" do

    before(:each) do
        load_raw_emails_data
        ActionController::Base.consider_all_requests_local = false
    end

    after(:each) do
         ActionController::Base.consider_all_requests_local = true
    end

    it "should render a 404 for unrouteable URLs" do
        get("/frobsnasm")
        response.code.should == "404"
        response.body.should include("The page doesn't exist")        
    end
    it "should render a 404 for users that don't exist" do
        get("/user/wobsnasm")
        response.code.should == "404"
    end
    it "should render a 404 for bodies that don't exist" do
        get("/body/wobsnasm")
        response.code.should == "404"
    end
    it "should render a 500 for general errors" do
        ir = info_requests(:naughty_chicken_request)
        # Set an invalid state for the request. Note that update_attribute doesn't run the validations
        ir.update_attribute(:described_state, "crotchety")
        get("/request/#{ir.url_title}")
        response.code.should == "500"
    end
    it "should render a 403 for attempts at directory listing for attachments" do
        # make a fake cache
        foi_cache_path = File.join(File.dirname(__FILE__), '../../cache')
        FileUtils.mkdir_p(File.join(foi_cache_path, "views/en/request/101/101/response/1/attach/html/1"))
        get("/request/101/response/1/attach/html/1/" )
        response.code.should == "403"
        get("/request/101/response/1/attach/html" )
        response.code.should == "403" 
    end
    it "should render a 404 for non-existent 'details' pages for requests" do
        get("/details/request/wobble" )
        response.code.should == "404"
    end
end


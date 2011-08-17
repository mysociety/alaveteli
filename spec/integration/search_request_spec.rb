require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When searching" do
    it "should not strip quotes from quoted query" do
        request_via_redirect("post", "/search", :query => '"mouse stilton"')
        response.body.should include("&quot;mouse stilton&quot;")
    end
end


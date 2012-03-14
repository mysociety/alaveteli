require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When viewing requests" do

    before(:each) do
        load_raw_emails_data
    end

    it "should not make endlessly recursive JSON <link>s" do
        @dog_request = info_requests(:fancy_dog_request)
        get "request/#{@dog_request.url_title}?unfold=1"
        response.body.should_not include("dog?unfold=1.json")
        response.body.should include("dog.json?unfold=1")
    end

end


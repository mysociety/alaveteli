require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When searching" do

    before(:each) do
        load_raw_emails_data
        rebuild_xapian_index
    end

    it "should not strip quotes from quoted query" do
        request_via_redirect("post", "/search", :query => '"mouse stilton"')
        response.body.should include("&quot;mouse stilton&quot;")
    end

    it "should correctly execute simple search" do
        request_via_redirect("post", "/search",
                             :query => 'bob'
                             )
        response.body.should include("FOI requests")
    end

    it "should correctly filter searches for requests" do
        request_via_redirect("post", "/search/bob/requests")
        response.body.should_not include("One person found")
        n = 4 # The number of requests that contain the word "bob" somewhere
              # in the email text. At present this is:
              # - fancy_dog_request
              # - naughty_chicken_request
              # - boring_request
              # - another_boring_request
              #
              # In other words it is all requests made by Bob Smith
              # except for badger_request, which he did not sign.
        response.body.should include("FOI requests 1 to #{n} of #{n}")
    end
    it "should correctly filter searches for users" do
        request_via_redirect("post", "/search/bob/users")
        response.body.should include("One person found")
        response.body.should_not include("FOI requests 1 to")
    end

    it "should correctly filter searches for successful requests" do
        request_via_redirect("post", "/search/requests",
                             :query => "bob",
                             :latest_status => ['successful'])
        n = 2 # The number of *successful* requests that contain the word "bob" somewhere
              # in the email text. At present this is:
              # - boring_request
              # - another_boring_request
        response.body.should include("FOI requests 1 to #{n} of #{n}")
    end

    it "should correctly filter searches for comments" do
        request_via_redirect("post", "/search/requests",
                             :query => "daftest",
                             :request_variety => ['comments'])
        response.body.should include("One FOI request found")

        request_via_redirect("post", "/search/requests",
                             :query => "daftest",
                             :request_variety => ['response','sent'])
        response.body.should include("no results matching your query")
    end

end


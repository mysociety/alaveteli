require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "When searching" do

    fixtures [
        :users,
        :public_bodies,
        :public_body_translations,
        :public_body_versions,
        :info_requests,
        :raw_emails,
        :outgoing_messages,
        :incoming_messages,
        :comments,
        :info_request_events,
        :track_things,
    ]

    before(:each) do
        emails = raw_emails.clone
        load_raw_emails_data(emails)
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
        response.body.should include("FOI requests 1 to 2 of 2")
    end
    it "should correctly filter searches for users" do
        request_via_redirect("post", "/search/bob/users")   
        response.body.should include("One person found")
        response.body.should_not include("FOI requests 1 to 2 of 2")
    end

    it "should correctly filter searches for successful requests" do
        request_via_redirect("post", "/search",
                             :query => "bob",
                             :latest_status => ['successful'])
        response.body.should include("no results matching your query")
    end

    it "should correctly filter searches for comments" do
        request_via_redirect("post", "/search",
                             :query => "daftest",
                             :request_variety => ['comments'])
        response.body.should include("One FOI request found")

        request_via_redirect("post", "/search",
                             :query => "daftest",
                             :request_variety => ['response','sent'])
        response.body.should include("no results matching your query")
    end

end


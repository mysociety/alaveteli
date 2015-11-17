# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When searching" do

  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it "should not strip quotes from quoted query" do
    request_via_redirect("get", "/search", :query => '"mouse stilton"')
    expect(response.body).to include("&quot;mouse stilton&quot;")
  end

  it "should redirect requests with search in query string to URL-based page" do
    get '/search/all?query=bob'
    expect(response).to redirect_to "/en/search/bob/all"
  end

  it "should correctly execute simple search" do
    request_via_redirect("get", "/search",
                         :query => 'bob'
                         )
    expect(response.body).to include("FOI requests")
  end

  it "should not log a logged-in user out" do
    with_forgery_protection do
      user = FactoryGirl.create(:user)
      user_session = login(user)
      using_session(user_session) do
        visit frontpage_path
        fill_in "navigation_search_button", :with => 'test'
        click_button "Search"
        expect(page.body).to include(user.name)
      end
    end
  end

  it "should correctly filter searches for requests" do
    request_via_redirect("get", "/search/bob/requests")
    expect(response.body).not_to include("One person found")
    n = 4 # The number of requests that contain the word "bob" somewhere
    # in the email text. At present this is:
    # - fancy_dog_request
    # - naughty_chicken_request
    # - boring_request
    # - another_boring_request
    #
    # In other words it is all requests made by Bob Smith
    # except for badger_request, which he did not sign.
    expect(response.body).to include("FOI requests 1 to #{n} of #{n}")
  end
  it "should correctly filter searches for users" do
    request_via_redirect("get", "/search/bob/users")
    expect(response.body).to include("One person found")
    expect(response.body).not_to include("FOI requests 1 to")
  end

  it "should correctly filter searches for successful requests" do
    request_via_redirect("get", "/search/requests",
                         :query => "bob",
                         :latest_status => ['successful'])
    n = 2 # The number of *successful* requests that contain the word "bob" somewhere
    # in the email text. At present this is:
    # - boring_request
    # - another_boring_request
    expect(response.body).to include("FOI requests 1 to #{n} of #{n}")
  end

  it "should correctly filter searches for comments" do
    request_via_redirect("get", "/search/requests",
                         :query => "daftest",
                         :request_variety => ['comments'])
    expect(response.body).to include("One FOI request found")

    request_via_redirect("get", "/search/requests",
                         :query => "daftest",
                         :request_variety => ['response','sent'])
    expect(response.body).to include("no results matching your query")
  end

end

require File.dirname(__FILE__) + '/../spec_helper'

describe RequestController, "when listing all requests" do
    fixtures :info_requests
  
    it "should be successful" do
        get :list
        response.should be_success
    end

    it "should render with 'list' template" do
        get :list
        response.should render_template('list')
    end

    it "should assign the first page of results" do
        # XXX probably should load more than one page of requests into db here :)
        
        get :list
        assigns[:info_requests] == [ 
            info_requests(:fancy_dog_request), 
            info_requests(:naughty_chicken_request)
        ]
    end

end

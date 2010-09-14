require File.dirname(__FILE__) + '/../../spec_helper'

describe "when listing recent requests" do
  
    before do
        assigns[:page] = 1
        assigns[:per_page] = 10

        # we're not testing the interlock plugin's cache
        template.stub!(:view_cache).and_yield
    end
      
    def make_mock_event 
        return mock_model(InfoRequestEvent, 
            :info_request => mock_model(InfoRequest, 
                :title => 'Title', 
                :url_title => 'title',
                :display_status => 'awaiting_response',
                :calculate_status => 'awaiting_response',
                :public_body => mock_model(PublicBody, :name => 'Test Quango', :url_name => 'testquango'),
                :user => mock_model(User, :name => 'Test User', :url_name => 'testuser')
            ),
            :incoming_message => nil, :is_incoming_message? => false,
            :outgoing_message => nil, :is_outgoing_message? => false,
            :comment => nil,          :is_comment? => false,
            :event_type => 'sent',
            :created_at => Time.now - 4.days,
            :search_text_main => ''
        )
    end

    it "should be successful" do
        assigns[:list_results] = [ make_mock_event, make_mock_event ]
        assigns[:matches_estimated] = 2

        render "request/list"

        response.should have_tag("div.request_listing")
        response.should_not have_tag("p", /No requests of this sort yet/m)
    end

    it "should cope with no results" do
        assigns[:list_results] = [ ]
        assigns[:matches_estimated] = 0

        render "request/list"
        response.should have_tag("p", /No requests of this sort yet/m)
        response.should_not have_tag("div.request_listing")
    end

end


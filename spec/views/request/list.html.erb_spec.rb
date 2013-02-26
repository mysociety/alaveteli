require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request/list" do
  
    before do
        assign :page, 1
        assign :per_page, 10
    end
      
    def make_mock_event 
        return mock_model(InfoRequestEvent, 
            :info_request => mock_model(InfoRequest, 
                :title => 'Title', 
                :url_title => 'title',
                :display_status => 'awaiting_response',
                :calculate_status => 'awaiting_response',
                :public_body => mock_model(PublicBody, :name => 'Test Quango', :url_name => 'testquango'),
                :user => mock_model(User, :name => 'Test User', :url_name => 'testuser'),
                :is_external? => false
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
        assign :list_results, [ make_mock_event, make_mock_event ]
        assign :matches_estimated, 2
        assign :show_no_more_than, 100
        render
        response.should have_selector("div.request_listing")
        response.should_not have_selector("p", :content => "No requests of this sort yet")
    end

    it "should cope with no results" do
        assign :list_results, [ ]
        assign :matches_estimated, 0
        assign :show_no_more_than, 0
        render
        response.should have_selector("p", :content => "No requests of this sort yet")
        response.should_not have_selector("div.request_listing")
    end

end


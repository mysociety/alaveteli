require File.dirname(__FILE__) + '/../spec_helper'

describe "when viewing a body" do

    before do
        @pb = mock_model(PublicBody, 
                         :name => 'Test Quango', 
                         :short_name => 'tq',
                         :url_name => 'testquango', 
                         :notes => '',
                         :type_of_authority => 'A public body',
                         :eir_only? => nil,
                         :info_requests => [1, 2, 3, 4], # out of sync with Xapian
                         :publication_scheme => '',
                         :calculated_home_page => '')
        @xap = mock_model(ActsAsXapian::Search, :matches_estimated => 2)
        @xap.stub!(:results).and_return([
          { :model => mock_event },
          { :model => mock_event }
        ])

        assigns[:public_body] = @pb
        assigns[:track_thing] = mock_model(TrackThing, :track_type => 'public_body_updates', :public_body => @pb )
        assigns[:xapian_requests] = @xap
        assigns[:page] = 1
        assigns[:per_page] = 10
    end

    it "should be successful" do
        render "body/show"
        response.should have_tag("h1", "Test Quango")
    end

    it "should tell total number of requests" do
        render "body/show"
        response.should have_tag("h2", "4 Freedom of Information requests made")
    end

    it "should cope with no results" do
        @xap.stub!(:results).and_return([])
        render "body/show"
        response.should have_tag("p", /Nobody has made any Freedom of Information requests/m)
    end

    it "should cope with Xapian being down" do
        assigns[:xapian_requests] = nil
        render "body/show"
        response.should have_tag("p", /The search index is currently offline/m)
    end

end

def mock_event 
    return mock_model(InfoRequestEvent, 
        :info_request => mock_model(InfoRequest, 
            :title => 'Title', 
            :url_title => 'title',
            :display_status => 'awaiting_response',
            :calculate_status => 'awaiting_response',
            :public_body => @pb,
            :user => mock_model(User, :name => 'Test User', :url_name => 'testuser')
        ),
        :incoming_message => nil,
        :outgoing_message => nil,
        :comment => nil,
        :event_type => 'sent',
        :created_at => Time.now - 4.days,
        :search_text_main => ''
    )
end


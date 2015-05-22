# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "public_body/show" do
    before do
        @pb = mock_model(PublicBody,
                         :name => 'Test Quango',
                         :short_name => 'tq',
                         :url_name => 'testquango',
                         :notes => '',
                         :tags => [],
                         :eir_only? => nil,
                         :info_requests => [1, 2, 3, 4], # out of sync with Xapian
                         :publication_scheme => '',
                         :disclosure_log => '',
                         :calculated_home_page => '')
        @pb.stub!(:is_requestable?).and_return(true)
        @pb.stub!(:special_not_requestable_reason?).and_return(false)
        @pb.stub!(:has_notes?).and_return(false)
        @pb.stub!(:has_tag?).and_return(false)
        @xap = mock(ActsAsXapian::Search, :matches_estimated => 2)
        @xap.stub!(:results).and_return([
          { :model => mock_event },
          { :model => mock_event }
        ])

        assign(:public_body, @pb)
        assign(:track_thing, mock_model(TrackThing,
            :track_type => 'public_body_updates', :public_body => @pb, :params => {}))
        assign(:xapian_requests, @xap)
        assign(:page, 1)
        assign(:per_page, 10)
        assign(:number_of_visible_requests, 4)
    end

    it "should be successful" do
        render
        controller.response.should be_success
    end

    it "should show the body's name" do
        render
        response.should have_selector('h1', :content => "Test Quango")
    end

    it "should tell total number of requests" do
        render
        response.should match "4 requests"
    end

    it "should cope with no results" do
        assign(:number_of_visible_requests, 0)
        render
        response.should have_selector('p', :content => "Nobody has made any Freedom of Information requests")
    end

    it "should cope with Xapian being down" do
        assign(:xapian_requests, nil)
        render
        response.should match "The search index is currently offline"
    end

end

def mock_event
    return mock_model(InfoRequestEvent,
        :info_request => mock_model(InfoRequest,
            :title => 'Title',
            :url_title => 'title',
            :display_status => 'waiting_response',
            :calculate_status => 'waiting_response',
            :public_body => @pb,
            :is_external? => false,
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


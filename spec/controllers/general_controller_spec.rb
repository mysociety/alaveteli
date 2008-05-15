require File.dirname(__FILE__) + '/../spec_helper'

def rebuild_xapian_index
    rebuild_name = File.dirname(__FILE__) + '/../../script/rebuild-xapian-index'
    Kernel.system(rebuild_name) or raise "failed to launch rebuild-xapian-index"
end

describe GeneralController, "when searching" do
    integrate_views
    fixtures :users, :outgoing_messages, :incoming_messages, :info_requests, :info_request_events, :public_bodies

    before do
        # XXX - what is proper way to do this only once?
        if not $general_controller_built_xapian_index
            rebuild_xapian_index
            $general_controller_built_xapian_index = true
        end
    end

    it "should render the front page successfully" do
        get :frontpage
        response.should be_success
    end

    it "when doing public body AJAX search should return list of matches" do
        get :auto_complete_for_public_body_query, :public_body => { :query => "humpa" }
        assigns[:public_bodies] = [ public_bodies(:humpadink_public_body) ]
        response.should render_template('_public_body_query')
    end

    it "when front page public body search has exact name match, should redirect to public body page" do
        post :frontpage, :public_body => { :query => public_bodies(:geraldine_public_body).name }
        response.should redirect_to(:controller => 'body', :action => 'show', :url_name => public_bodies(:geraldine_public_body).url_name)
    end

    it "should redirect from search query URL to pretty URL" do
        post :search_redirect, :query => "mouse" # query hidden in POST parameters
        response.should redirect_to(:action => 'search', :combined => "mouse") # URL /search/:query
    end
  
    it "should find info request when searching for '\"fancy dog\"'" do
        get :search, :combined => ['"fancy dog"']
        response.should render_template('search')

        assigns[:xapian_requests].matches_estimated.should == 1
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_outgoing_message_event)

        assigns[:xapian_requests].words_to_highlight == ["fancy", "dog"]
    end

    it "should show help when searching for nothing" do
        get :search_redirect, :query => nil
        response.should render_template('search')
        assigns[:total_hits].should be_nil
        assigns[:query].should be_nil
    end

    it "should find public body and incoming message when searching for 'geraldine quango'" do
        get :search, :combined => ['geraldine quango']
        response.should render_template('search')

        assigns[:xapian_requests].matches_estimated.should == 1
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].should == info_request_events(:useless_incoming_message_event)

        assigns[:xapian_bodies].matches_estimated.should == 1
        assigns[:xapian_bodies].results.size.should == 1
        assigns[:xapian_bodies].results[0][:model].should == public_bodies(:geraldine_public_body)
    end
end


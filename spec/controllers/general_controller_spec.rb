require File.dirname(__FILE__) + '/../spec_helper'

describe GeneralController, "when searching" do
    integrate_views
    fixtures :users, :outgoing_messages, :incoming_messages, :info_requests, :info_request_events, :public_bodies

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
        #ActsAsXapian.rebuild_index([PublicBody, User, InfoRequestEvent])
        ActsAsXapian.update_index
        get :search, :combined => ['"fancy dog"']
        response.should render_template('search')

        assigns[:search_hits].should == 1
        assigns[:search_results].size.should == 1
        assigns[:search_results][0][:model].should == info_request_events(:useless_outgoing_message_event)

        assigns[:highlight_words].should == ["fancy", "dog"]
    end

    it "should show help when searching for nothing" do
        get :search_redirect, :query => nil
        response.should render_template('search')
        assigns[:search_hits].should be_nil
        assigns[:query].should be_nil
    end

    it "should find public body and incoming message (in that order) when searching for 'geraldine quango'" do
        ActsAsXapian.update_index

        get :search, :combined => ['geraldine quango']
        response.should render_template('search')

        assigns[:search_hits].should == 2
        assigns[:search_results].size.should == 2
        assigns[:search_results][0][:model].should == public_bodies(:geraldine_public_body)
        assigns[:search_results][1][:model].should == info_request_events(:useless_incoming_message_event)
    end

    it "should find incoming message and public body (in that order) when searching for 'geraldine quango', newest first" do
        ActsAsXapian.update_index

        get :search, :combined => ['geraldine quango','newest']
        response.should render_template('search')

        assigns[:search_hits].should == 2
        assigns[:search_results].size.should == 2
        assigns[:search_results][0][:model].should == info_request_events(:useless_incoming_message_event)
        assigns[:search_results][1][:model].should == public_bodies(:geraldine_public_body)
    end


    #    assigns[:display_user].should == users(:bob_smith_user)
end


require File.dirname(__FILE__) + '/../spec_helper'

describe RequestController, "when listing recent requests" do
    
    before(:all) do
        rebuild_xapian_index
    end
    
    it "should be successful" do
        get :list, :view => 'recent'
        response.should be_success
    end

    it "should render with 'list' template" do
        get :list, :view => 'recent'
        response.should render_template('list')
    end

    it "should assign the first page of results" do
        InfoRequest.should_receive(:full_search).
          with([InfoRequestEvent],"variety:sent", "created_at", anything, anything, anything, anything).
          and_return((1..25).to_a)
        get :list, :view => 'recent'
        assigns[:xapian_object].size.should == 25
    end
end


describe RequestController, "when showing one request" do
    
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
  
    it "should be successful" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should be_success
    end

    it "should render with 'show' template" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('show')
    end

    it "should assign the request" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        assigns[:info_request].should == info_requests(:fancy_dog_request)
    end

    it "should redirect from a numeric URL to pretty one" do
        get :show, :url_title => info_requests(:naughty_chicken_request).id
        response.should redirect_to(:action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title)
    end

    it "should not show hidden requests" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'hidden'
        ir.save!

        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('hidden')
    end
    
    describe 'when handling an update_status parameter' do
        
        before do 
            mock_request = mock_model(InfoRequest, :url_title => 'test_title', 
                                                   :title => 'test title', 
                                                   :null_object => true)
            InfoRequest.stub!(:find_by_url_title).and_return(mock_request)
        end

        it 'should assign the "update status" flag to the view as true if the parameter is present' do
            get :show, :url_title => 'test_title', :update_status => 1
            assigns[:update_status].should be_true
        end

        it 'should assign the "update status" flag to the view as true if the parameter is present' do
            get :show, :url_title => 'test_title'
            assigns[:update_status].should be_false
        end
        
    end

    describe 'when handling incoming mail' do 
      
        integrate_views
        
        it "should receive incoming messages, send email to creator, and show them" do
            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            size_before = assigns[:info_request_events].size

            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.body.should =~ /You have a new response to the Freedom of Information request/

            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            (assigns[:info_request_events].size - size_before).should == 1
        end
      
        it "should download attachments" do
            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            response.content_type.should == "text/html"
            size_before = assigns[:info_request_events].size

            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            (assigns[:info_request_events].size - size_before).should == 1

            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2
            response.content_type.should == "text/plain"
            response.should have_text(/Second hello/)        
            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 3
            response.content_type.should == "text/plain"
            response.should have_text(/First hello/)        
        end

        it "should not download attachments if hidden" do
            ir = info_requests(:fancy_dog_request) 
            ir.prominence = 'hidden'
            ir.save!
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2
            response.content_type.should == "text/html"
            response.should_not have_text(/Second hello/)        
            response.should render_template('request/hidden')
            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 3
            response.content_type.should == "text/html"
            response.should_not have_text(/First hello/)        
            response.should render_template('request/hidden')
        end
    end
end

# XXX do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{RAILS_ROOT}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when creating a new request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :public_bodies, :users

    before do
        @user = users(:bob_smith_user)
        @body = public_bodies(:geraldine_public_body)
    end
        
    it "should redirect to front page if no public body specified" do
        get :new
        response.should redirect_to(:controller => 'general', :action => 'frontpage')
    end

    it "should redirect to front page if no public body specified, when logged in" do
        session[:user_id] = @user.id
        get :new
        response.should redirect_to(:controller => 'general', :action => 'frontpage')
    end

    it "should accept a public body parameter" do
        get :new, :info_request => { :public_body_id => @body.id } 
        assigns[:info_request].public_body.should == @body    
        response.should render_template('new')
    end

    it "should give an error and render 'new' template when a summary isn't given" do
        post :new, :info_request => { :public_body_id => @body.id },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 1
        assigns[:info_request].errors[:title].should_not be_nil
        response.should render_template('new')
    end

    it "should show preview when input is good" do
        post :new, { :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 1
        }
        response.should render_template('preview')
    end

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0
        }
        post :new, params
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        # post_redirect.post_params.should == params # XXX get this working. there's a : vs '' problem amongst others
    end

    it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
        session[:user_id] = @user.id
        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0

        ir_array = InfoRequest.find(:all, :conditions => ["title = ?", "Why is your quango called Geraldine?"])
        ir_array.size.should == 1
        ir = ir_array[0]
        ir.outgoing_messages.size.should == 1
        om = ir.outgoing_messages[0]
        om.body.should == "This is a silly letter. It is too short to be interesting."

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /This is a silly letter. It is too short to be interesting./

        response.should redirect_to(:action => 'show', :url_title => ir.url_title)
    end

    it "should give an error if the same request is submitted twice" do
        session[:user_id] = @user.id

        # We use raw_body here, so white space is the same
        post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
            :title => info_requests(:fancy_dog_request).title },
            :outgoing_message => { :body => info_requests(:fancy_dog_request).outgoing_messages[0].raw_body},
            :submitted_new_request => 1, :preview => 0, :mouse_house => 1
        response.should render_template('new')
    end

    it "should give an error if the same request is submitted twice with extra whitespace in the body" do
        # This only works for PostgreSQL databases which have regexp_replace -
        # see model method InfoRequest.find_by_existing_request for more info
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            session[:user_id] = @user.id

            post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
                :title => info_requests(:fancy_dog_request).title },
                :outgoing_message => { :body => "\n" + info_requests(:fancy_dog_request).outgoing_messages[0].body + " "},
                :submitted_new_request => 1, :preview => 0, :mouse_house => 1
            response.should render_template('new')
        end
    end

    it "should let you submit another request with the same title" do
        session[:user_id] = @user.id

        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0

        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a sensible letter. It is too long to be boring." },
            :submitted_new_request => 1, :preview => 0

        ir_array = InfoRequest.find(:all, :conditions => ["title = ?", "Why is your quango called Geraldine?"], :order => "id")
        ir_array.size.should == 2

        ir = ir_array[0]
        ir2 = ir_array[1]

        ir.url_title.should_not == ir2.url_title

        response.should redirect_to(:action => 'show', :url_title => ir2.url_title)
    end

end

# These go with the previous set, but use mocks instead of fixtures. 
# TODO harmonise these
describe RequestController, "when making a new request" do

    before do
        @user = mock_model(User, :id => 3481, :name => 'Testy')
        @user.stub!(:get_undescribed_requests).and_return([])
        @user.stub!(:can_file_requests?).and_return(true)
        User.stub!(:find).and_return(@user)

        @body = mock_model(PublicBody, :id => 314, :eir_only? => false, :is_requestable? => true)
        PublicBody.stub!(:find).and_return(@body)
    end

    it "should allow you to have one undescribed request" do
        @user.stub!(:get_undescribed_requests).and_return([ 1 ])
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('new')
    end

    it "should fail if more than one request undescribed" do
        @user.stub!(:get_undescribed_requests).and_return([ 1, 2 ])
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('new_please_describe')
    end

    it "should fail if user is banned" do
        @user.stub!(:can_file_requests?).and_return(false)
        @user.should_receive(:can_fail_html).and_return('FAIL!')
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('user/banned')
    end

end

describe RequestController, "when viewing an individual response for reply/followup" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages, :comments # all needed as integrating views
  
    it "should ask for login if you are logged in as wrong person" do
        session[:user_id] = users(:silly_name_user).id
        get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.should render_template('user/wrong_user')
    end

    it "should show the response if you are logged in as right person" do
        session[:user_id] = users(:bob_smith_user).id
        get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.should render_template('show_response')
    end
end

describe RequestController, "when classifying an information request" do

    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages, :comments # all needed as integrating views

    before do 
        @dog_request = info_requests(:fancy_dog_request)
        @dog_request.stub!(:is_old_unclassified?).and_return(false)
        InfoRequest.stub!(:find).and_return(@dog_request)
    end

    def post_status(status)
        post :describe_state, :incoming_message => { :described_state => status }, 
                              :id => @dog_request.id, 
                              :last_info_request_event_id => @dog_request.last_event_id_needing_description, 
                              :submitted_describe_state => 1
    end

    it "should require login" do
        post_status('rejected')
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it 'should ask whether the request is old and unclassified' do 
        @dog_request.should_receive(:is_old_unclassified?)
        post_status('rejected')
    end
    
    it "should not classify the request if logged in as the wrong user" do
        session[:user_id] = users(:silly_name_user).id
        post_status('rejected')
        response.should render_template('user/wrong_user')
    end
    
    describe 'when the request is old and unclassified' do 
        
        before do 
            @dog_request.stub!(:is_old_unclassified?).and_return(true)
            RequestMailer.stub!(:deliver_old_unclassified_updated)
        end
        
        describe 'when the user is not logged in' do 
            
            it 'should require login' do 
                session[:user_id] = nil
                post_status('rejected')
                post_redirect = PostRedirect.get_last_post_redirect
                response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
            end
            
        end
        
        describe 'when the user is logged in as a different user' do 
            
            before do
                @other_user = mock_model(User)
                session[:user_id] = users(:silly_name_user).id
            end
            
            it 'should classify the request' do
                @dog_request.stub!(:calculate_status).and_return('rejected') 
                @dog_request.should_receive(:set_described_state).with('rejected')
                post_status('rejected')
            end
        
            it 'should log a status update event' do 
                expected_params = {:user_id => users(:silly_name_user).id, 
                                   :old_described_state => 'waiting_response', 
                                   :described_state => 'rejected'}
                @dog_request.should_receive(:log_event).with("status_update", expected_params)
                post_status('rejected')
            end
            
            it 'should send an email to the requester letting them know someone has updated the status of their request' do 
                RequestMailer.should_receive(:deliver_old_unclassified_updated)
                post_status('rejected')
            end
            
            it 'should redirect to the request page' do 
                post_status('rejected')
                response.should redirect_to(:action => 'show', :controller => 'request', :url_title => @dog_request.url_title)
            end
            
            it 'should show a message thanking the user for a good deed' do 
                post_status('rejected')
                flash[:notice].should == '<p>Thank you for updating this request!</p>'
            end
            
        end
    end
    
    describe 'when logged in as an admin user' do 
    
        before do 
            @admin_user = users(:admin_user)
            session[:user_id] = @admin_user.id
            @dog_request = info_requests(:fancy_dog_request)
            InfoRequest.stub!(:find).and_return(@dog_request)
        end

        it 'should update the status of the request' do 
            @dog_request.stub!(:calculate_status).and_return('rejected')
            @dog_request.should_receive(:set_described_state).with('rejected')
            post_status('rejected')
        end
        
        it 'should log a status update event' do 
            expected_params = {:user_id => @admin_user.id, 
                               :old_described_state => 'waiting_response', 
                               :described_state => 'rejected'}
            @dog_request.should_receive(:log_event).with("status_update", expected_params)
            post_status('rejected')
        end
        
        it 'should show the message "The request status has been updated"' do 
            post_status('rejected')
            flash[:notice].should == '<p>The request status has been updated</p>'
        end
        
        it 'should redirect to the page that shows the request' do 
            post_status('rejected')
            response.should redirect_to(:action => 'show', :controller => 'request', :url_title => @dog_request.url_title)
        end

    end
    
    describe 'when logged in as the requestor' do 
    
        before do 
            @request_owner = users(:bob_smith_user)
            session[:user_id] = @request_owner.id
            @dog_request.awaiting_description.should == true
        end
        
        it "should successfully classify response if logged in as user controlling request" do
            post_status('rejected')
            response.should redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
            @dog_request.reload
            @dog_request.awaiting_description.should == false
            @dog_request.described_state.should == 'rejected'
            @dog_request.get_last_response_event.should == info_request_events(:useless_incoming_message_event)
            @dog_request.get_last_response_event.calculated_state.should == 'rejected'
        end

        it 'should not log a status update event' do 
            @dog_request.should_not_receive(:log_event)
            post_status('rejected')
        end
        
        it 'should not send an email to the requester letting them know someone has updated the status of their request' do 
            RequestMailer.should_not_receive(:deliver_old_unclassified_updated)
            post_status('rejected')
        end
        
        it "should send email when classified as requires_admin" do
            post :describe_state, :incoming_message => { :described_state => "requires_admin" }, :id => @dog_request.id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => @dog_request.last_event_id_needing_description, :submitted_describe_state => 1
            response.should redirect_to(:controller => 'help', :action => 'contact')

            @dog_request.reload
            @dog_request.awaiting_description.should == false
            @dog_request.described_state.should == 'requires_admin'
            @dog_request.get_last_response_event.calculated_state.should == 'requires_admin'

            deliveries = ActionMailer::Base.deliveries
            deliveries.size.should == 1
            mail = deliveries[0]
            mail.body.should =~ /as needing admin/
            mail.from_addrs.to_s.should == @request_owner.name_and_email
        end
        
    end
    
    describe 'when redirecting after a successful status update by the request owner' do 
        
        before do 
            @request_owner = users(:bob_smith_user)
            session[:user_id] = @request_owner.id
            @dog_request = info_requests(:fancy_dog_request)
            InfoRequest.stub!(:find).and_return(@dog_request)
        end

        def request_url
            "request/#{@dog_request.url_title}"
        end
        
        def expect_redirect(status, redirect_path)
            post_status(status)
            response.should redirect_to("http://test.host/#{redirect_path}")
        end
        
        it 'should redirect to the "request url" with a message in the right tense when status is updated to "waiting response" and the response is not overdue' do
            @dog_request.stub!(:date_response_required_by).and_return(Time.now.to_date+1)
            expect_redirect("waiting_response", "request/#{@dog_request.url_title}")
            flash[:notice].should match(/should get a response/)
        end
    
        it 'should redirect to the "request url" with a message in the right tense when status is updated to "waiting response" and the response is overdue' do 
            @dog_request.stub!(:date_response_required_by).and_return(Time.now.to_date-1)
            expect_redirect('waiting_response', request_url)
            flash[:notice].should match(/should have got a response/)
        end
        
        it 'should redirect to the "request url" when status is updated to "not held"' do 
            expect_redirect('not_held', request_url)
        end
        
        it 'should redirect to the "request url" when status is updated to "successful"' do 
            expect_redirect('successful', request_url)
        end
        
        it 'should redirect to the "unhappy url" when status is updated to "rejected"' do 
            expect_redirect('rejected', "help/unhappy/#{@dog_request.url_title}")
        end
        
        it 'should redirect to the "unhappy url" when status is updated to "partially successful"' do 
            expect_redirect('partially_successful', "help/unhappy/#{@dog_request.url_title}")
        end
        
        it 'should redirect to the "response url" when status is updated to "waiting clarification" and there is a last response' do 
            incoming_message = mock_model(IncomingMessage)
            @dog_request.stub!(:get_last_response).and_return(incoming_message)
            expect_redirect('waiting_clarification', "request/#{@dog_request.id}/response/#{incoming_message.id}")
        end
        
        it 'should redirect to the "response no followup url" when status is updated to "waiting clarification" and there are no events needing description' do 
            @dog_request.stub!(:get_last_response).and_return(nil)
            expect_redirect('waiting_clarification', "request/#{@dog_request.id}/response")
        end

        it 'should redirect to the "respond to last url" when status is updated to "gone postal"' do 
            expect_redirect('gone_postal', "request/#{@dog_request.id}/response/1?gone_postal=1")
        end
        
        it 'should redirect to the "request url" when status is updated to "internal review"' do 
            expect_redirect('internal_review', request_url)
        end
        
        it 'should redirect to the "help general url" when status is updated to "requires admin"' do 
            expect_redirect('requires_admin', "help/contact")
        end
        
        it 'should redirect to the "help general url" when status is updated to "error message"' do 
            expect_redirect('error_message', "help/contact")
        end
        
        it 'should redirect to the "request url" when status is updated to "user_withdrawn"' do 
            expect_redirect('user_withdrawn', request_url)
        end
         
    end
end

describe RequestController, "when sending a followup message" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
  
    it "should require login" do
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should not let you if you are logged in as the wrong user" do
        session[:user_id] = users(:silly_name_user).id
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        response.should render_template('user/wrong_user')
    end

    it "should give an error and render 'show_response' template when a body isn't given" do
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :outgoing_message => { :body => "", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

        # XXX how do I check the error message here?
        response.should render_template('show_response')
    end


    it "should send the follow up message if you are the right user" do
        # fake that this is a clarification
        info_requests(:fancy_dog_request).set_described_state('waiting_clarification')
        info_requests(:fancy_dog_request).described_state.should == 'waiting_clarification'
        info_requests(:fancy_dog_request).get_last_response_event.calculated_state.should == 'waiting_clarification'

        # make the followup
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

        # check it worked
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /What a useless response! You suck./
        mail.to_addrs.to_s.should == "FOI Person <foiperson@localhost>"

        response.should redirect_to(:action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)

        # and that the status changed
        info_requests(:fancy_dog_request).reload
        info_requests(:fancy_dog_request).described_state.should == 'waiting_response'
        info_requests(:fancy_dog_request).get_last_response_event.calculated_state.should == 'waiting_clarification'
    end


end

# XXX Stuff after here should probably be in request_mailer_spec.rb - but then
# it can't check the URLs in the emails I don't think, ugh.

describe RequestController, "sending overdue request alerts" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
 
    it "should send an overdue alert mail to creators of overdue requests" do
        RequestMailer.alert_overdue_requests

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /20 working days/
        mail.to_addrs.to_s.should == info_requests(:naughty_chicken_request).user.name_and_email

        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        session[:user_id].should be_nil
        controller.test_code_redirect_by_email_token(mail_token, self) # XXX hack to avoid having to call User controller for email link
        session[:user_id].should == info_requests(:naughty_chicken_request).user.id

        response.should render_template('show_response')
        assigns[:info_request].should == info_requests(:naughty_chicken_request)
    end

end

describe RequestController, "sending unclassified new response reminder alerts" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages, :comments # all needed as integrating views
 
    it "should send an alert" do
        RequestMailer.alert_new_response_reminders

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 2 # sufficiently late it sends reminder too
        mail = deliveries[0]
        mail.body.should =~ /To let us know/
        mail.to_addrs.to_s.should == info_requests(:fancy_dog_request).user.name_and_email
        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        session[:user_id].should be_nil
        controller.test_code_redirect_by_email_token(mail_token, self) # XXX hack to avoid having to call User controller for email link
        session[:user_id].should == info_requests(:fancy_dog_request).user.id

        response.should render_template('show')
        assigns[:info_request].should == info_requests(:fancy_dog_request)
        # XXX should check anchor tag here :) that it goes to last new response
    end

end

describe RequestController, "clarification required alerts" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
 
    it "should send an alert" do
        ir = info_requests(:fancy_dog_request)
        ir.set_described_state('waiting_clarification')
        # this is pretty horrid, but will do :) need to make it waiting
        # clarification more than 3 days ago for the alerts to go out.
        ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
        ir.reload

        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /asked you to explain/
        mail.to_addrs.to_s.should == info_requests(:fancy_dog_request).user.name_and_email
        mail.body =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        session[:user_id].should be_nil
        controller.test_code_redirect_by_email_token(mail_token, self) # XXX hack to avoid having to call User controller for email link
        session[:user_id].should == info_requests(:fancy_dog_request).user.id

        response.should render_template('show_response')
        assigns[:info_request].should == info_requests(:fancy_dog_request)
    end

end

describe RequestController, "comment alerts" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages, :comments # all needed as integrating views
 
    it "should send an alert" do
        # delete ficture comment and make new one, so is in last month (as
        # alerts are only for comments in last month, see
        # RequestMailer.alert_comment_on_request)
        existing_comment = info_requests(:fancy_dog_request).comments[0]
        existing_comment.info_request_events[0].destroy
        existing_comment.destroy
        new_comment = info_requests(:fancy_dog_request).add_comment('I love making annotations.', users(:bob_smith_user))

        # send comment alert
        RequestMailer.alert_comment_on_request

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /has annotated your/
        mail.to_addrs.to_s.should == info_requests(:fancy_dog_request).user.name_and_email
        mail.body =~ /(http:\/\/.*)/
        mail_url = $1

        # XXX check mail_url here somehow, can't call comment_url like this:
        # mail_url.should == comment_url(comments(:silly_comment))

        #STDERR.puts mail.body
    end

    it "should send an alert when there are two new comments" do
        # add second comment - that one being new will be enough for
        # RequestMailer.alert_comment_on_request to also find the one in the
        # fixture.
        new_comment = info_requests(:fancy_dog_request).add_comment('Not as daft as this one', users(:bob_smith_user))

        RequestMailer.alert_comment_on_request

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /There are 2 new annotations/
        mail.to_addrs.to_s.should == info_requests(:fancy_dog_request).user.name_and_email
        mail.body =~ /(http:\/\/.*)/
        mail_url = $1

        # XXX check mail_url here somehow, can't call comment_url like this:
        # mail_url.should == comment_url(comments(:silly_comment))

        #STDERR.puts mail.body
    end

end

describe RequestController, "when viewing comments" do
    integrate_views
    fixtures :users

    it "should link to the user who submitted it" do
        session[:user_id] = users(:bob_smith_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.body.should have_tag("div#comment-1 h2", /Silly.*left an annotation/m) 
        response.body.should_not have_tag("div#comment-1 h2", /You.*left an annotation/m) 
    end

    it "should say if you were the user who submitted it" do
        session[:user_id] = users(:silly_name_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.body.should_not have_tag("div#comment-1 h2", /Silly.*left an annotation/m) 
        response.body.should have_tag("div#comment-1 h2", /You.*left an annotation/m) 
    end

end







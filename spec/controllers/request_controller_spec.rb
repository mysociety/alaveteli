require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'json'

describe RequestController, "when listing recent requests" do
    fixtures :users, :public_bodies, :public_body_translations, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events

    before(:each) do
        load_raw_emails_data(raw_emails)
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

    it "should filter requests" do
        get :list, :view => 'all'
        assigns[:list_results].size.should == 2
        get :list, :view => 'successful'
        assigns[:list_results].size.should == 0
    end

    it "should filter requests by date" do
        get :list, :view => 'all', :request_date_before => '13/10/2007'
        assigns[:list_results].size.should == 1
        get :list, :view => 'all', :request_date_after => '13/10/2007'
        assigns[:list_results].size.should == 1
        get :list, :view => 'all', :request_date_after => '10/10/2007', :request_date_before => '01/01/2010'
        assigns[:list_results].size.should == 2
    end

    it "should assign the first page of results" do
        xap_results = mock_model(ActsAsXapian::Search, 
                   :results => (1..25).to_a.map { |m| { :model => m } },
                   :matches_estimated => 103)

        InfoRequest.should_receive(:full_search).
          with([InfoRequestEvent]," variety:sent", "created_at", anything, anything, anything, anything).
          and_return(xap_results)
        get :list, :view => 'recent'
        assigns[:list_results].size.should == 25
    end
end

describe RequestController, "when showing one request" do
    
    fixtures :public_bodies, :public_body_translations, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events # all needed as integrating views
    
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

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

            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => ['hello.txt']
            response.content_type.should == "text/plain"
            response.should have_text(/Second hello/)
            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 3, :file_name => ['hello.txt']
            response.content_type.should == "text/plain"
            response.should have_text(/First hello/)
        end

        it "should convert message body to UTF8" do
            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('iso8859_2_raw_email.email', ir.incoming_email)
            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            response.should have_text(/tënde/u)
        end

        it "should generate valid HTML verson of plain text attachments " do
            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
            get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => ['hello.txt.html'], :skip_cache => 1
            response.content_type.should == "text/html"
            response.should have_text(/Second hello/)
        end

        it "should treat attachments with unknown extensions as binary" do
            ir = info_requests(:fancy_dog_request)
            receive_incoming_mail('incoming-request-attachment-unknown-extension.email', ir.incoming_email)
            
            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => ['hello.qwglhm']
            response.content_type.should == "application/octet-stream"
            response.should have_text(/an unusual sort of file/)
        end

        it "should not download attachments with wrong file name" do
            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            lambda {
                get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, 
                    :file_name => ['http://trying.to.hack']
            }.should raise_error(ActiveRecord::RecordNotFound)
        end

        it "should censor attachments downloaded as binary" do
            ir = info_requests(:fancy_dog_request) 

            censor_rule = CensorRule.new()
            censor_rule.text = "Second"
            censor_rule.replacement = "Mouse"
            censor_rule.last_edit_editor = "unknown"
            censor_rule.last_edit_comment = "none"
            ir.censor_rules << censor_rule

            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => ['hello.txt']
            response.content_type.should == "text/plain"
            response.should have_text(/xxxxxx hello/)
        end

        it "should censor with rules on the user (rather than the request)" do
            ir = info_requests(:fancy_dog_request) 

            censor_rule = CensorRule.new()
            censor_rule.text = "Second"
            censor_rule.replacement = "Mouse"
            censor_rule.last_edit_editor = "unknown"
            censor_rule.last_edit_comment = "none"
            ir.user.censor_rules << censor_rule

            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => ['hello.txt']
            response.content_type.should == "text/plain"
            response.should have_text(/xxxxxx hello/)
        end

        it "should censor attachment names" do
            ir = info_requests(:fancy_dog_request) 
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            response.body.should have_tag("p.attachment strong", /hello.txt/m) 

            censor_rule = CensorRule.new()
            censor_rule.text = "hello.txt"
            censor_rule.replacement = "goodbye.txt"
            censor_rule.last_edit_editor = "unknown"
            censor_rule.last_edit_comment = "none"
            ir.censor_rules << censor_rule

            get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
            response.body.should have_tag("p.attachment strong", /goodbye.txt/m) 
        end

        it "should make a zipfile available, which has a different URL when it changes" do
            ir = info_requests(:fancy_dog_request) 
            session[:user_id] = ir.user.id # bob_smith_user
            receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
            title = 'why_do_you_have_such_a_fancy_dog'
            get :download_entire_request, :url_title => title
            assigns[:url_path].should have_text(/#{title}.zip$/)
            old_path = assigns[:url_path]
            response.location.should have_text(/#{assigns[:url_path]}$/)
            zipfile = Zip::ZipFile.open(File.join(File.dirname(__FILE__), "../../cache/zips", old_path)) { |zipfile|
                zipfile.count.should == 2
            }
            receive_incoming_mail('incoming-request-attachment-unknown-extension.email', ir.incoming_email)
            get :download_entire_request, :url_title => title
            assigns[:url_path].should have_text(/#{title}.zip$/)
            response.location.should have_text(/#{assigns[:url_path]}/)
            assigns[:url_path].should_not == old_path
            zipfile = Zip::ZipFile.open(File.join(File.dirname(__FILE__), "../../cache/zips", assigns[:url_path])) { |zipfile|
                zipfile.count.should == 4
zipfile.entries.each {|x| puts x.name}
            }
        end
    end
end

describe RequestController, "when changing prominence of a request" do
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :info_request_events # all needed as integrating views

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should not show hidden requests" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'hidden'
        ir.save!

        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('hidden')
    end

    it "should not show hidden requests even if logged in as their owner" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'hidden'
        ir.save!

        session[:user_id] = ir.user.id # bob_smith_user
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('hidden')
    end

    it "should show hidden requests if logged in as super user" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'hidden'
        ir.save!

        session[:user_id] = users(:admin_user)
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('show')
    end

    it "should not show requester_only requests if you're not logged in" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'requester_only'
        ir.save!

        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('hidden')
    end

    it "should show requester_only requests to requester and admin if logged in" do
        ir = info_requests(:fancy_dog_request)
        ir.prominence = 'requester_only'
        ir.save!

        session[:user_id] = users(:silly_name_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('hidden')

        session[:user_id] = ir.user.id # bob_smith_user
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('show')

        session[:user_id] = users(:admin_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('show')

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
 
# XXX do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{RAILS_ROOT}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when searching for an authority" do
    fixtures :public_bodies, :users

    # Whether or not sign-in is required for this step is configurable,
    # so we make sure we're logged in, just in case
    before do
        @user = users(:bob_smith_user)
    end
    
    it "should return nothing for the empty query string" do
        session[:user_id] = @user.id
        get :select_authority, :query => ""
        
        response.should render_template('select_authority')
        assigns[:xapian_requests].results.size == 0
    end

    it "should return matching bodies" do
        session[:user_id] = @user.id
        get :select_authority, :query => "Quango"
        
        response.should render_template('select_authority')
        assigns[:xapian_requests].results.size == 1
        assigns[:xapian_requests].results[0][:model].name.should == public_bodies(:geraldine_public_body).name
    end
end

describe RequestController, "when creating a new request" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :outgoing_messages

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

    it "should redirect 'bad request' page when a body has no email address" do
        @body.request_email = ""
        @body.save!
        get :new, :public_body_id => @body.id
        response.should render_template('new_bad_contact')
    end

    it "should accept a public body parameter" do
        get :new, :public_body_id => @body.id
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

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0
        }
        post :new, params
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
        # post_redirect.post_params.should == params # XXX get this working. there's a : vs '' problem amongst others
    end

    it "should show preview when input is good" do
        session[:user_id] = @user.id
        post :new, { :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 1
        }
        response.should render_template('preview')
    end

    it "should allow re-editing of a request" do
        post :new, :info_request => { :public_body_id => @body.id,
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0,
            :reedit => "Re-edit this request"
        response.should render_template('new')
    end

    it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
        session[:user_id] = @user.id
        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
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
        # This test uses an explicit path because it's relied in
        # Google Analytics goals:
        response.redirected_to.should =~ /request\/why_is_your_quango_called_gerald\/new$/
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

    it "should let you submit another request with the same title" do
        session[:user_id] = @user.id

        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0

        post :new, :info_request => { :public_body_id => @body.id, 
            :title => "Why is your quango called Geraldine?", :tag_string => "" },
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
        @user.stub!(:can_leave_requests_undescribed?).and_return(false)
        @user.stub!(:can_file_requests?).and_return(true)
        @user.stub!(:locale).and_return("en")
        User.stub!(:find).and_return(@user)

        @body = mock_model(PublicBody, :id => 314, :eir_only? => false, :is_requestable? => true, :name => "Test Quango")
        PublicBody.stub!(:find).and_return(@body)
    end

    it "should allow you to have one undescribed request" do
        @user.stub!(:get_undescribed_requests).and_return([ 1 ])
        @user.stub!(:can_leave_requests_undescribed?).and_return(false)
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('new')
    end

    it "should fail if more than one request undescribed" do
        @user.stub!(:get_undescribed_requests).and_return([ 1, 2 ])
        @user.stub!(:can_leave_requests_undescribed?).and_return(false)
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('new_please_describe')
    end

    it "should allow you if more than one request undescribed but are allowed to leave requests undescribed" do
        @user.stub!(:get_undescribed_requests).and_return([ 1, 2 ])
        @user.stub!(:can_leave_requests_undescribed?).and_return(true)
        session[:user_id] = @user.id
        get :new, :public_body_id => @body.id
        response.should render_template('new')
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
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events # all needed as integrating views

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

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

    it "should offer the opportunity to reply to the main address" do
        session[:user_id] = users(:bob_smith_user).id
        get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.body.should have_tag("div#other_recipients ul li", /the main FOI contact address for/)
    end

    it "should offer an opportunity to reply to another address" do
        session[:user_id] = users(:bob_smith_user).id
        ir = info_requests(:fancy_dog_request)
        ir.allow_new_responses_from = "anybody"
        ir.save!
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "Frob <frob@bonce.com>")
        get :show_response, :id => ir.id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.body.should have_tag("div#other_recipients ul li", /Frob/)
    end

    it "should not show individual responses if request hidden, even if request owner" do
        ir = info_requests(:fancy_dog_request) 
        ir.prominence = 'hidden'
        ir.save!

        session[:user_id] = users(:bob_smith_user).id
        get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
        response.should render_template('request/hidden')
    end
end

describe RequestController, "when classifying an information request" do

    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events # all needed as integrating views

    before(:each) do 
        @dog_request = info_requests(:fancy_dog_request)
        @dog_request.stub!(:is_old_unclassified?).and_return(false)
        InfoRequest.stub!(:find).and_return(@dog_request)
        load_raw_emails_data(raw_emails)
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
                flash[:notice].should == 'Thank you for updating this request!'
            end
            
        end
    end
    
    describe 'when logged in as an admin user who is not the actual requester' do 
    
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
            flash[:notice].should == 'Thank you for updating this request!'
        end
     end

    describe 'when logged in as an admin user who is also the actual requester' do 
    
        before do 
            @admin_user = users(:admin_user)
            session[:user_id] = @admin_user.id
            @dog_request = info_requests(:fancy_dog_request)
            @dog_request.user = @admin_user
            @dog_request.save!
            InfoRequest.stub!(:find).and_return(@dog_request)
        end

        it 'should update the status of the request' do 
            @dog_request.stub!(:calculate_status).and_return('rejected')
            @dog_request.should_receive(:set_described_state).with('rejected')
            post_status('rejected')
        end
       
        it 'should not log a status update event' do 
            @dog_request.should_not_receive(:log_event)
            post_status('rejected')
        end

        it 'should not send an email to the requester letting them know someone has updated the status of their request' do 
            RequestMailer.should_not_receive(:deliver_old_unclassified_updated)
            post_status('rejected')
        end
 
        it 'should say it is showing advice as to what to do next' do 
            post_status('rejected')
            flash[:notice].should match(/Here is what to do now/) 
        end
        
        it 'should redirect to the unhappy page' do 
            post_status('rejected')
            response.should redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
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

        it 'should say it is showing advice as to what to do next' do 
            post_status('rejected')
            flash[:notice].should match(/Here is what to do now/) 
        end
        
        it 'should redirect to the unhappy page' do 
            post_status('rejected')
            response.should redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
        end

        it "knows about extended states" do
            InfoRequest.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
            InfoRequest.send(:include, InfoRequestCustomStates)
            InfoRequest.class_eval('@@custom_states_loaded = true')
            RequestController.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
            RequestController.send(:include, RequestControllerCustomStates)
            RequestController.class_eval('@@custom_states_loaded = true')
            Time.stub!(:now).and_return(Time.utc(2007, 11, 10, 00, 01)) 
            post_status('deadline_extended')
            flash[:notice].should == 'Authority has requested extension of the deadline.'
        end
    end
    
    describe 'when redirecting after a successful status update by the request owner' do 
        
        before do 
            @request_owner = users(:bob_smith_user)
            session[:user_id] = @request_owner.id
            @dog_request = info_requests(:fancy_dog_request)
            InfoRequest.stub!(:find).and_return(@dog_request)
            ActionController::Routing::Routes.filters.clear
        end

        def request_url
            "request/#{@dog_request.url_title}"
        end

        def unhappy_url
            "help/unhappy/#{@dog_request.url_title}"
        end
         
        def expect_redirect(status, redirect_path)
            post_status(status)
            response.should redirect_to("http://test.host/#{redirect_path}")
        end
        
        it 'should redirect to the "request url" with a message in the right tense when status is updated to "waiting response" and the response is not overdue' do
            @dog_request.stub!(:date_response_required_by).and_return(Time.now.to_date+1)
            @dog_request.stub!(:date_very_overdue_after).and_return(Time.now.to_date+40)

            expect_redirect("waiting_response", "request/#{@dog_request.url_title}")
            flash[:notice].should match(/should get a response/)
        end
    
        it 'should redirect to the "request url" with a message in the right tense when status is updated to "waiting response" and the response is overdue' do 
            @dog_request.stub!(:date_response_required_by).and_return(Time.now.to_date-1)
            @dog_request.stub!(:date_very_overdue_after).and_return(Time.now.to_date+40)
            expect_redirect('waiting_response', request_url)
            flash[:notice].should match(/should have got a response/)
        end

        it 'should redirect to the "request url" with a message in the right tense when status is updated to "waiting response" and the response is overdue' do 
            @dog_request.stub!(:date_response_required_by).and_return(Time.now.to_date-2)
            @dog_request.stub!(:date_very_overdue_after).and_return(Time.now.to_date-1)
            expect_redirect('waiting_response', unhappy_url)
            flash[:notice].should match(/is long overdue/)
            flash[:notice].should match(/by more than 40 working days/)
            flash[:notice].should match(/within 20 working days/)
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
            expect_redirect('gone_postal', "request/#{@dog_request.id}/response/#{@dog_request.get_last_response.id}?gone_postal=1")
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
        
        it 'should redirect to the "respond to last url url" when status is updated to "user_withdrawn"' do 
            expect_redirect('user_withdrawn', "request/#{@dog_request.id}/response/#{@dog_request.get_last_response.id}")
        end
         
    end
end

describe RequestController, "when sending a followup message" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :info_request_events # all needed as integrating views

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

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

    it "should show preview when input is good" do
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 1
        response.should render_template('followup_preview')
    end

    it "should allow re-editing of a preview" do
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 0, :reedit => "Re-edit this request"
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

    it "should give an error if the same followup is submitted twice" do
        session[:user_id] = users(:bob_smith_user).id

        # make the followup once
        post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        response.should redirect_to(:action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)
        
        # second time should give an error
        post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        # XXX how do I check the error message here?
        response.should render_template('show_response')
    end

end

# XXX Stuff after here should probably be in request_mailer_spec.rb - but then
# it can't check the URLs in the emails I don't think, ugh.

describe RequestController, "sending overdue request alerts" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :info_request_events # all needed as integrating views
    
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should send an overdue alert mail to creators of overdue requests" do
        chicken_request = info_requests(:naughty_chicken_request)
        chicken_request.outgoing_messages[0].last_sent_at = Time.now() - 30.days
        chicken_request.outgoing_messages[0].save!

        RequestMailer.alert_overdue_requests

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /promptly, as normally/
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

    it "should include clause for schools when sending an overdue alert mail to creators of overdue requests" do
        chicken_request = info_requests(:naughty_chicken_request)
        chicken_request.outgoing_messages[0].last_sent_at = Time.now() - 30.days
        chicken_request.outgoing_messages[0].save!

        chicken_request.public_body.tag_string = "school"
        chicken_request.public_body.save!

        RequestMailer.alert_overdue_requests

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /promptly, as normally/
        mail.to_addrs.to_s.should == info_requests(:naughty_chicken_request).user.name_and_email
    end

    it "should send not actually send the overdue alert if the user is banned" do
        user = info_requests(:naughty_chicken_request).user
        user.ban_text = 'Banned'
        user.save!

        RequestMailer.alert_overdue_requests

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end

    it "should send a very overdue alert mail to creators of very overdue requests" do
        chicken_request = info_requests(:naughty_chicken_request)
        chicken_request.outgoing_messages[0].last_sent_at = Time.now() - 60.days
        chicken_request.outgoing_messages[0].save!

        RequestMailer.alert_overdue_requests

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /required by law/
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
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events # all needed as integrating views

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should send an alert" do
        RequestMailer.alert_new_response_reminders

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 3 # sufficiently late it sends reminders too
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
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :info_request_events # all needed as integrating views
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

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

    it "should not send an alert if you are banned" do
        ir = info_requests(:fancy_dog_request)
        ir.set_described_state('waiting_clarification')

        ir.user.ban_text = 'Banned'
        ir.user.save!

        # this is pretty horrid, but will do :) need to make it waiting
        # clarification more than 3 days ago for the alerts to go out.
        ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
        ir.reload

        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end

end

describe RequestController, "comment alerts" do
    integrate_views
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events # all needed as integrating views
    before(:each) do
        load_raw_emails_data(raw_emails)
    end
 
    it "should send an alert (once and once only)" do
        # delete ficture comment and make new one, so is in last month (as
        # alerts are only for comments in last month, see
        # RequestMailer.alert_comment_on_request)
        existing_comment = info_requests(:fancy_dog_request).comments[0]
        existing_comment.info_request_events[0].destroy
        existing_comment.destroy
        new_comment = info_requests(:fancy_dog_request).add_comment('I really love making annotations.', users(:silly_name_user))

        # send comment alert
        RequestMailer.alert_comment_on_request
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries[0]
        mail.body.should =~ /has annotated your/
        mail.to_addrs.to_s.should == info_requests(:fancy_dog_request).user.name_and_email
        mail.body =~ /(http:\/\/.*)/
        mail_url = $1

        # XXX check mail_url here somehow, can't call comment_url like this:
        # mail_url.should == comment_url(comments(:silly_comment))

        
        # check if we send again, no more go out
        deliveries.clear
        RequestMailer.alert_comment_on_request
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end

    it "should not send an alert when you comment on your own request" do
        # delete ficture comment and make new one, so is in last month (as
        # alerts are only for comments in last month, see
        # RequestMailer.alert_comment_on_request)
        existing_comment = info_requests(:fancy_dog_request).comments[0]
        existing_comment.info_request_events[0].destroy
        existing_comment.destroy
        new_comment = info_requests(:fancy_dog_request).add_comment('I also love making annotations.', users(:bob_smith_user))

        # try to send comment alert
        RequestMailer.alert_comment_on_request

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 0
    end

    it "should send an alert when there are two new comments" do
        # add two comments - the second one sould be ignored, as is by the user who made the request.
        # the new comment here, will cause the one in the fixture to be picked up as a new comment by alert_comment_on_request also.
        new_comment = info_requests(:fancy_dog_request).add_comment('Not as daft as this one', users(:silly_name_user))
        new_comment = info_requests(:fancy_dog_request).add_comment('Or this one!!!', users(:bob_smith_user))

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

    end

end

describe RequestController, "when viewing comments" do
    integrate_views
    fixtures :users, :info_requests, :raw_emails, :incoming_messages
    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should link to the user who submitted it" do
        session[:user_id] = users(:bob_smith_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.body.should have_tag("div#comment-1 h2", /Silly.*left an annotation/m) 
        response.body.should_not have_tag("div#comment-1 h2", /You.*left an annotation/m) 
    end

    it "should link to the user who submitted to it, even if it is you" do
        session[:user_id] = users(:silly_name_user).id
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.body.should have_tag("div#comment-1 h2", /Silly.*left an annotation/m) 
        response.body.should_not have_tag("div#comment-1 h2", /You.*left an annotation/m) 
    end

end


describe RequestController, "authority uploads a response from the web interface" do
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :info_request_events

    before(:all) do
        # domain after the @ is used for authentication of FOI officers, so to test it
        # we need a user which isn't at localhost.
        @normal_user = User.new(:name => "Mr. Normal", :email => "normal-user@flourish.org",  
                                      :password => PostRedirect.generate_random_token)
        @normal_user.save!

        @foi_officer_user = User.new(:name => "The Geraldine Quango", :email => "geraldine-requests@localhost", 
                                      :password => PostRedirect.generate_random_token)
        @foi_officer_user.save!
    end
  
    it "should require login to view the form to upload" do
        @ir = info_requests(:fancy_dog_request) 
        @ir.public_body.is_foi_officer?(@normal_user).should == false
        session[:user_id] = @normal_user.id

        get :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('user/wrong_user')
    end

   it "should let you view upload form if you are an FOI officer" do
        @ir = info_requests(:fancy_dog_request) 
        @ir.public_body.is_foi_officer?(@foi_officer_user).should == true
        session[:user_id] = @foi_officer_user.id

        get :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog'
        response.should render_template('request/upload_response')
    end

    it "should prevent uploads if you are not a requester" do
        @ir = info_requests(:fancy_dog_request) 
        incoming_before = @ir.incoming_messages.size
        session[:user_id] = @normal_user.id

        # post up a photo of the parrot
        parrot_upload = fixture_file_upload('files/parrot.png','image/png')
        post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog',
            :body => "Find attached a picture of a parrot",
            :file_1 => parrot_upload,
            :submitted_upload_response => 1
        response.should render_template('user/wrong_user')
    end

    it "should prevent entirely blank uploads" do
        session[:user_id] = @foi_officer_user.id

        post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog', :body => "", :submitted_upload_response => 1
        response.should render_template('request/upload_response')
        flash[:error].should match(/Please type a message/)
    end

    # How do I test a file upload in rails?
    # http://stackoverflow.com/questions/1178587/how-do-i-test-a-file-upload-in-rails
    it "should let the requester upload a file" do
        @ir = info_requests(:fancy_dog_request) 
        incoming_before = @ir.incoming_messages.size
        session[:user_id] = @foi_officer_user.id

        # post up a photo of the parrot
        parrot_upload = fixture_file_upload('files/parrot.png','image/png')
        post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog',
            :body => "Find attached a picture of a parrot",
            :file_1 => parrot_upload,
            :submitted_upload_response => 1

        response.should redirect_to(:action => 'show', :url_title => 'why_do_you_have_such_a_fancy_dog')
        flash[:notice].should match(/Thank you for responding to this FOI request/)

        # check there is a new attachment
        incoming_after = @ir.incoming_messages.size
        incoming_after.should == incoming_before + 1

        # check new attachment looks vaguely OK
        new_im = @ir.incoming_messages[-1]
        new_im.mail.body.should match(/Find attached a picture of a parrot/)
        attachments = new_im.get_attachments_for_display
        attachments.size.should == 1
        attachments[0].filename.should == "parrot.png"
        attachments[0].display_size.should == "94K"
    end
end

describe RequestController, "when showing JSON version for API" do
    
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events 

    before(:each) do
        load_raw_emails_data(raw_emails)
    end

    it "should return data in JSON form" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :format => 'json'

        ir = JSON.parse(response.body)
        ir.class.to_s.should == 'Hash'

        ir['url_title'].should == 'why_do_you_have_such_a_fancy_dog'
        ir['public_body']['url_name'].should == 'tgq'
        ir['user']['url_name'].should == 'bob_smith'
    end

end

describe RequestController, "when doing type ahead searches" do
    fixtures :public_bodies, :public_body_translations, :users, :info_requests, :raw_emails, :incoming_messages, :outgoing_messages, :comments, :info_request_events 

    it "should return nothing for the empty query string" do
        get :search_typeahead, :q => ""
        response.should render_template('request/_search_ahead.rhtml')
        assigns[:xapian_requests].results.size.should == 0
    end
    
    it "should return a request matching the given keyword, but not users with a matching description" do
        get :search_typeahead, :q => "chicken"
        response.should render_template('request/_search_ahead.rhtml')
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].title.should == info_requests(:naughty_chicken_request).title
    end

    it "should return all requests matching any of the given keywords" do
        get :search_typeahead, :q => "money dog"
        response.should render_template('request/_search_ahead.rhtml')
        assigns[:xapian_requests].results.size.should == 2
        assigns[:xapian_requests].results[0][:model].title.should == info_requests(:fancy_dog_request).title
        assigns[:xapian_requests].results[1][:model].title.should == info_requests(:naughty_chicken_request).title
    end

    it "should return partial matches" do
        get :search_typeahead, :q => "chick"  # 'chick' for 'chicken'
        response.should render_template('request/_search_ahead.rhtml')
        assigns[:xapian_requests].results.size.should == 1
        assigns[:xapian_requests].results[0][:model].title.should == info_requests(:naughty_chicken_request).title
    end
end



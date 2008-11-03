require File.dirname(__FILE__) + '/../spec_helper'

describe RequestController, "when listing all requests" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :info_request_events
  
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
        ActsAsXapian.update_index
        
        get :list

        # reverse-chronological order
        assigns[:xapian_object].matches_estimated.should == 2
        assigns[:xapian_object].results.size.should == 2
        assigns[:xapian_object].results[0][:model].should == info_request_events(:silly_outgoing_message_event)
        assigns[:xapian_object].results[1][:model].should == info_request_events(:useless_outgoing_message_event)
    end
end

describe RequestController, "when showing one request" do
    integrate_views
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
end

# XXX do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{RAILS_ROOT}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when creating a new request" do
    integrate_views
    fixtures :info_requests, :outgoing_messages, :public_bodies, :users

    it "should redirect to front page if no public body specified" do
        get :new
        response.should redirect_to(:controller => 'general', :action => 'frontpage')
    end

    it "should accept a public body parameter posted from the front page" do
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id } 
        assigns[:info_request].public_body.should == public_bodies(:geraldine_public_body)    
        response.should render_template('new')
    end

    it "should give an error and render 'new' template when a summary isn't given" do
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id },
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 1
        assigns[:info_request].errors[:title].should_not be_nil
        response.should render_template('new')
    end

    it "should show preview when input is good" do
        post :new, { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 1
        }
        response.should render_template('preview')
    end

    it "should redirect to sign in page when input is good and nobody is logged in" do
        params = { :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
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
        session[:user_id] = users(:bob_smith_user).id
        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
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
        session[:user_id] = users(:bob_smith_user).id

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
            session[:user_id] = users(:bob_smith_user).id

            post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id, 
                :title => info_requests(:fancy_dog_request).title },
                :outgoing_message => { :body => "\n" + info_requests(:fancy_dog_request).outgoing_messages[0].body + " "},
                :submitted_new_request => 1, :preview => 0, :mouse_house => 1
            response.should render_template('new')
        end
    end

    it "should let you submit another request with the same title" do
        session[:user_id] = users(:bob_smith_user).id

        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
            :title => "Why is your quango called Geraldine?"},
            :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
            :submitted_new_request => 1, :preview => 0

        post :new, :info_request => { :public_body_id => public_bodies(:geraldine_public_body).id, 
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

describe RequestController, "when classifying an individual response" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages, :comments # all needed as integrating views

    it "should require login" do
        post :describe_state, :incoming_message => { :described_state => "rejected" }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => info_request_events(:useless_incoming_message_event).id, :submitted_describe_state => 1
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should not classify response if logged in as wrong user" do
        session[:user_id] = users(:silly_name_user).id
        post :describe_state, :incoming_message => { :described_state => "rejected" }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => info_request_events(:useless_incoming_message_event).id, :submitted_describe_state => 1
        response.should render_template('user/wrong_user')
    end

    it "should successfully classify response if logged in as user controlling request" do
        info_requests(:fancy_dog_request).awaiting_description.should == true
        session[:user_id] = users(:bob_smith_user).id
        post :describe_state, :incoming_message => { :described_state => "rejected" }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => info_request_events(:silly_comment_event).id, :submitted_describe_state => 1
        response.should redirect_to(:controller => 'help', :action => 'unhappy')
        info_requests(:fancy_dog_request).reload
        info_requests(:fancy_dog_request).awaiting_description.should == false
        info_requests(:fancy_dog_request).described_state.should == 'rejected'
        info_requests(:fancy_dog_request).get_last_response_event.calculated_state.should == 'rejected'
    end

    it "should send email when classified as requires_admin" do
        info_requests(:fancy_dog_request).awaiting_description.should == true
        session[:user_id] = users(:bob_smith_user).id
        post :describe_state, :incoming_message => { :described_state => "requires_admin" }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => info_request_events(:silly_comment_event).id, :submitted_describe_state => 1
        response.should redirect_to(:controller => 'help', :action => 'contact')

        info_requests(:fancy_dog_request).reload
        info_requests(:fancy_dog_request).awaiting_description.should == false
        info_requests(:fancy_dog_request).described_state.should == 'requires_admin'
        info_requests(:fancy_dog_request).get_last_response_event.calculated_state.should == 'requires_admin'

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.body.should =~ /as being unusual/
        mail.from_addrs.to_s.should == users(:bob_smith_user).name_and_email
    end
end

describe RequestController, "when sending a followup message" do
    integrate_views
    fixtures :info_requests, :info_request_events, :public_bodies, :users, :incoming_messages, :raw_emails, :outgoing_messages # all needed as integrating views
  
    it "should require login" do
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck." }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        post_redirect = PostRedirect.get_last_post_redirect
        response.should redirect_to(:controller => 'user', :action => 'signin', :token => post_redirect.token)
    end

    it "should not let you if you are logged in as the wrong user" do
        session[:user_id] = users(:silly_name_user).id
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck." }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
        response.should render_template('user/wrong_user')
    end

    it "should give an error and render 'show_response' template when a body isn't given" do
        session[:user_id] = users(:bob_smith_user).id
        post :show_response, :outgoing_message => { :body => "" }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

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
        post :show_response, :outgoing_message => { :body => "What a useless response! You suck." }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

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







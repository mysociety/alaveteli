# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestController, "when listing recent requests" do
  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it "should be successful" do
    get :list, :view => 'all'
    expect(response).to be_success
  end

  it "should render with 'list' template" do
    get :list, :view => 'all'
    expect(response).to render_template('list')
  end

  it "should return 404 for pages we don't want to serve up" do
    xap_results = double(ActsAsXapian::Search,
                       :results => (1..25).to_a.map { |m| { :model => m } },
                       :matches_estimated => 1000000)
    expect {
      get :list, :view => 'all', :page => 100
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should not raise an error for a page param of less than zero, but should treat it as
        a param of 1' do
    expect{ get :list, :view => 'all', :page => "-1" }.not_to raise_error
    expect(assigns[:page]).to eq(1)
  end

end

describe RequestController, "when changing things that appear on the request page" do
  render_views

  it "should purge the downstream cache when mail is received" do
    # HACK: The holding pen is now being called (and created, if
    # this is the first time the holding pen has been initialised) in
    # InfoRequest#receive. This seemed to create a PurgeRequest for the
    # holding pen instead of the request under test. The solution was to
    # ensure the holding pen already exists before this spec.
    InfoRequest.holding_pen_request
    PurgeRequest.delete_all
    ir = info_requests(:fancy_dog_request)

    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)

    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end
  it "should purge the downstream cache when a comment is added" do
    ir = info_requests(:fancy_dog_request)
    new_comment = info_requests(:fancy_dog_request).add_comment('I also love making annotations.', users(:bob_smith_user))
    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end
  it "should purge the downstream cache when a followup is made" do
    session[:user_id] = users(:bob_smith_user).id
    ir = info_requests(:fancy_dog_request)
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => ir.id, :submitted_followup => 1
    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end
  it "should purge the downstream cache when the request is categorised" do
    ir = info_requests(:fancy_dog_request)
    ir.set_described_state('waiting_clarification')
    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end
  it "should purge the downstream cache when the authority data is changed" do
    ir = info_requests(:fancy_dog_request)
    ir.public_body.name = "Something new"
    ir.public_body.save!
    expect(PurgeRequest.all.map{|x| x.model_id}).to match_array(ir.public_body.info_requests.map{|x| x.id})
  end
  it "should purge the downstream cache when the user name is changed" do
    ir = info_requests(:fancy_dog_request)
    ir.user.name = "Something new"
    ir.user.save!
    expect(PurgeRequest.all.map{|x| x.model_id}).to match_array(ir.user.info_requests.map{|x| x.id})
  end
  it "should not purge the downstream cache when non-visible user details are changed" do
    ir = info_requests(:fancy_dog_request)
    ir.user.hashed_password = "some old hash"
    ir.user.save!
    expect(PurgeRequest.all.count).to eq(0)
  end
  it "should purge the downstream cache when censor rules have changed" do
    # TODO: really, CensorRules should execute expiry logic as part
    # of the after_save of the model. Currently this is part of
    # the AdminCensorRuleController logic, so must be tested from
    # there. Leaving this stub test in place as a reminder
  end
  it "should purge the downstream cache when something is hidden by an admin" do
    ir = info_requests(:fancy_dog_request)
    ir.prominence = 'hidden'
    ir.save!
    expect(PurgeRequest.all.first.model_id).to eq(ir.id)
  end
  it "should not create more than one entry for any given resource" do
    ir = info_requests(:fancy_dog_request)
    ir.prominence = 'hidden'
    ir.save!
    expect(PurgeRequest.all.count).to eq(1)
    ir = info_requests(:fancy_dog_request)
    ir.prominence = 'hidden'
    ir.save!
    expect(PurgeRequest.all.count).to eq(1)
  end
end

describe RequestController, "when showing one request" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should be successful" do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response).to be_success
  end

  it "should render with 'show' template" do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response).to render_template('show')
  end

  it "should show the request" do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response).to be_success
    expect(response.body).to include("Why do you have such a fancy dog?")
  end

  it "should assign the request" do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(assigns[:info_request]).to eq(info_requests(:fancy_dog_request))
  end

  it "should redirect from a numeric URL to pretty one" do
    get :show, :url_title => info_requests(:naughty_chicken_request).id.to_s
    expect(response).to redirect_to(:action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title)
  end

  it 'should show actions the request owner can take' do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response.body).to have_css('div#owner_actions')
  end

  describe 'when the request does allow comments' do
    it 'should have a comment link' do
      get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
        { :user_id => users(:admin_user).id }
      expect(response.body).to have_css('#anyone_actions', :text => "Add an annotation")
    end
  end

  describe 'when the request does not allow comments' do
    it 'should not have a comment link' do
      get :show, { :url_title => 'spam_1' },
        { :user_id => users(:admin_user).id }
      expect(response.body).not_to have_css('#anyone_actions', :text => "Add an annotation")
    end
  end

  context "when the request has not yet been reported" do
    it "should allow the user to report" do
      title = info_requests(:badger_request).url_title
      get :show, :url_title => title
      expect(response.body).not_to have_content("This request has been reported")
      expect(response.body).to have_content("Offensive?")
    end
  end

  context "when the request has been reported for admin attention" do
    before :each do
      info_requests(:fancy_dog_request).report!("", "", nil)
    end
    it "should inform the user" do
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(response.body).to have_content("This request has been reported")
      expect(response.body).not_to have_content("Offensive?")
    end

    context "and then deemed okay and left to complete" do
      before :each do
        info_requests(:fancy_dog_request).set_described_state("successful")
      end
      it "should let the user know that the administrators have not hidden this request" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        expect(response.body).to match(/the site administrators.*have not hidden it/)
      end
    end
  end

  describe 'when the request is being viewed by an admin' do

    describe 'if the request is awaiting description' do

      before do
        dog_request = info_requests(:fancy_dog_request)
        dog_request.awaiting_description = true
        dog_request.save!
      end

      it 'should show the describe state form' do
        get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
          { :user_id => users(:admin_user).id }
        expect(response.body).to have_css('div.describe_state_form')
      end

      it 'should ask the user to use the describe state from' do
        get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
          { :user_id => users(:admin_user).id }
        expect(response.body).to have_css('p#request_status', :text => "answer the question above")
      end

    end

    describe 'if the request is waiting for a response and very overdue' do

      before do
        dog_request = info_requests(:fancy_dog_request)
        dog_request.awaiting_description = false
        dog_request.described_state = 'waiting_response'
        dog_request.save!
        expect(dog_request.calculate_status).to eq('waiting_response_very_overdue')
      end

      it 'should give a link to requesting an internal review' do
        get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
          { :user_id => users(:admin_user).id }
        expect(response.body).to have_css('p#request_status', :text => "requesting an internal review")
      end

    end

    describe 'if the request is waiting clarification' do

      before do
        dog_request = info_requests(:fancy_dog_request)
        dog_request.awaiting_description = false
        dog_request.described_state = 'waiting_clarification'
        dog_request.save!
        expect(dog_request.calculate_status).to eq('waiting_clarification')
      end

      it 'should give a link to make a followup' do
        get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
          { :user_id => users(:admin_user).id }
        expect(response.body).to have_css('p#request_status a', :text => "send a follow up message")
      end
    end

  end

  describe 'when showing an external request' do

    describe 'when viewing with no logged in user' do

      it 'should be successful' do
        get :show, { :url_title => 'balalas' }, { :user_id => nil }
        expect(response).to be_success
      end

      it 'should not display actions the request owner can take' do
        get :show, :url_title => 'balalas'
        expect(response.body).not_to have_css('div#owner_actions')
      end

    end

    describe 'when the request is being viewed by an admin' do

      def make_request
        get :show, { :url_title => 'balalas' }, { :user_id => users(:admin_user).id }
      end

      it 'should be successful' do
        make_request
        expect(response).to be_success
      end

      describe 'if the request is awaiting description' do

        before do
          external_request = info_requests(:external_request)
          external_request.awaiting_description = true
          external_request.save!
        end

        it 'should not show the describe state form' do
          make_request
          expect(response.body).not_to have_css('div.describe_state_form')
        end

        it 'should not ask the user to use the describe state form' do
          make_request
          expect(response.body).not_to have_css('p#request_status', :text => "answer the question above")
        end

      end

      describe 'if the request is waiting for a response and very overdue' do

        before do
          external_request = info_requests(:external_request)
          external_request.awaiting_description = false
          external_request.described_state = 'waiting_response'
          external_request.save!
          expect(external_request.calculate_status).to eq('waiting_response_very_overdue')
        end

        it 'should not give a link to requesting an internal review' do
          make_request
          expect(response.body).not_to have_css('p#request_status', :text => "requesting an internal review")
        end
      end

      describe 'if the request is waiting clarification' do

        before do
          external_request = info_requests(:external_request)
          external_request.awaiting_description = false
          external_request.described_state = 'waiting_clarification'
          external_request.save!
          expect(external_request.calculate_status).to eq('waiting_clarification')
        end

        it 'should not give a link to make a followup' do
          make_request
          expect(response.body).not_to have_css('p#request_status a', :text => "send a follow up message")
        end

        it 'should not give a link to sign in (in the request status paragraph)' do
          make_request
          expect(response.body).not_to have_css('p#request_status a', :text => "sign in")
        end

      end

    end

  end

  describe 'when handling an update_status parameter' do

    describe 'when the request is external' do

      it 'should assign the "update status" flag to the view as falsey if the parameter is present' do
        get :show, :url_title => 'balalas', :update_status => 1
        expect(assigns[:update_status]).to be_falsey
      end

      it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
        get :show, :url_title => 'balalas'
        expect(assigns[:update_status]).to be_falsey
      end

    end

    it 'should assign the "update status" flag to the view as truthy if the parameter is present' do
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :update_status => 1
      expect(assigns[:update_status]).to be_truthy
    end

    it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(assigns[:update_status]).to be_falsey
    end

    it 'should require login' do
      session[:user_id] = nil
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :update_status => 1
      expect(response).to redirect_to(:controller => 'user',
                                      :action => 'signin',
                                      :token => get_last_post_redirect.token)
    end

    it 'should work if logged in as the requester' do
      session[:user_id] = users(:bob_smith_user).id
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :update_status => 1
      expect(response).to render_template "request/show"
    end

    it 'should not work if logged in as not the requester' do
      session[:user_id] = users(:silly_name_user).id
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :update_status => 1
      expect(response).to render_template "user/wrong_user"
    end

    it 'should work if logged in as an admin user' do
      session[:user_id] = users(:admin_user).id
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :update_status => 1
      expect(response).to render_template "request/show"
    end
  end

  describe 'when handling incoming mail' do

    render_views

    it "should receive incoming messages, send email to creator, and show them" do
      ir = info_requests(:fancy_dog_request)
      ir.incoming_messages.each { |x| x.parse_raw_email! }

      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      size_before = assigns[:info_request_events].size

      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/You have a new response to the Freedom of Information request/)

      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(assigns[:info_request_events].size - size_before).to eq(1)
    end

    it "should download attachments" do
      ir = info_requests(:fancy_dog_request)
      ir.incoming_messages.each { |x| x.parse_raw_email!(true) }

      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(response.content_type).to eq("text/html")
      size_before = assigns[:info_request_events].size

      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(assigns[:info_request_events].size - size_before).to eq(1)
      ir.reload

      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt', :skip_cache => 1
      expect(response.content_type).to eq("text/plain")
      expect(response.body).to have_content "Second hello"

      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 3, :file_name => 'hello world.txt', :skip_cache => 1
      expect(response.content_type).to eq("text/plain")
      expect(response.body).to have_content "First hello"
    end

    it 'should cache an attachment on a request with normal prominence' do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      expect(@controller).to receive(:foi_fragment_cache_write)
      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id,
        :id => ir.id,
        :part => 2,
        :file_name => 'hello world.txt'
    end

    it "should convert message body to UTF8" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('iso8859_2_raw_email.email', ir.incoming_email)
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(response.body).to have_content "tënde"
    end

    it "should generate valid HTML verson of plain text attachments" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Second hello"
    end

    # This is a regression test for a bug where URLs of this form were causing 500 errors
    # instead of 404s.
    #
    # (Note that in fact only the integer-prefix of the URL part is used, so there are
    # *some* “ugly URLs containing a request id that isn't an integer” that actually return
    # a 200 response. The point is that IDs of this sort were triggering an error in the
    # error-handling path, causing the wrong sort of error response to be returned in the
    # case where the integer prefix referred to the wrong request.)
    #
    # https://github.com/mysociety/alaveteli/issues/351
    it "should return 404 for ugly URLs containing a request id that isn't an integer" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      ugly_id = "55195"
      expect {
        get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ugly_id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ugly_id, :part => 2, :file_name => 'hello world.txt', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it "should return 404 when incoming message and request ids don't match" do
      ir = info_requests(:fancy_dog_request)
      wrong_id = info_requests(:naughty_chicken_request).id
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      expect {
        get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => wrong_id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it "should return 404 for ugly URLs contain a request id that isn't an integer, even if the integer prefix refers to an actual request" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      ugly_id = "%d95" % [info_requests(:naughty_chicken_request).id]

      expect {
        get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ugly_id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ugly_id, :part => 2, :file_name => 'hello world.txt', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it "should return 404 when incoming message and request ids don't match" do
      ir = info_requests(:fancy_dog_request)
      wrong_id = info_requests(:naughty_chicken_request).id
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      expect {
        get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => wrong_id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should generate valid HTML verson of PDF attachments" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-pdf-attachment.email', ir.incoming_email)
      ir.reload
      get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'fs 50379341.pdf.html', :skip_cache => 1
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Walberswick Parish Council"
    end

    it "should not cause a reparsing of the raw email, even when the attachment can't be found" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload
      attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(ir.incoming_messages[1].get_attachments_for_display, 2, 'hello world.txt')
      expect(attachment.body).to have_content "Second hello"

      # change the raw_email associated with the message; this only be reparsed when explicitly asked for
      ir.incoming_messages[1].raw_email.data = ir.incoming_messages[1].raw_email.data.sub("Second", "Third")
      # asking for an attachment by the wrong filename should result in redirecting
      # back to the incoming message, but shouldn't cause a reparse:
      get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt.baz.html', :skip_cache => 1
      expect(response.status).to eq(303)

      attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(ir.incoming_messages[1].get_attachments_for_display, 2, 'hello world.txt')
      expect(attachment.body).to have_content "Second hello"

      # ...nor should asking for it by its correct filename...
      get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      expect(response.body).not_to have_content "Third hello"

      # ...but if we explicitly ask for attachments to be extracted, then they should be
      force = true
      ir.incoming_messages[1].parse_raw_email!(force)
      ir.reload
      attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(ir.incoming_messages[1].get_attachments_for_display, 2, 'hello world.txt')
      expect(attachment.body).to have_content "Third hello"
      get :get_attachment_as_html, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt.html', :skip_cache => 1
      expect(response.body).to have_content "Third hello"
    end

    it "should redirect to the incoming message if there's a wrong part number and an ambiguous filename" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
      ir.reload

      im = ir.incoming_messages[1]

      attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(im.get_attachments_for_display, 5, 'hello world.txt')
      expect(attachment).to be_nil

      get :get_attachment_as_html, :incoming_message_id => im.id, :id => ir.id, :part => 5, :file_name => 'hello world.txt', :skip_cache => 1
      expect(response.status).to eq(303)
      new_location = response.header['Location']
      expect(new_location).to match(/request\/#{ir.url_title}#incoming-#{im.id}/)
    end

    it "should find a uniquely named filename even if the URL part number was wrong" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-pdf-attachment.email', ir.incoming_email)
      ir.reload
      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 5, :file_name => 'fs 50379341.pdf', :skip_cache => 1
      expect(response.content_type).to eq("application/pdf")
    end

    it "should treat attachments with unknown extensions as binary" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-attachment-unknown-extension.email', ir.incoming_email)
      ir.reload

      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello.qwglhm', :skip_cache => 1
      expect(response.content_type).to eq("application/octet-stream")
      expect(response.body).to have_content "an unusual sort of file"
    end

    it "should not download attachments with wrong file name" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

      get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'http://trying.to.hack'
      expect(response.status).to eq(303)
    end

    it "should sanitise HTML attachments" do
      incoming_message = FactoryGirl.create(:incoming_message_with_html_attachment)
      get :get_attachment, :incoming_message_id => incoming_message.id,
        :id => incoming_message.info_request.id,
        :part => 2,
        :file_name => 'interesting.html',
        :skip_cache => 1
      expect(response.body).not_to match("script")
      expect(response.body).not_to match("interesting")
      expect(response.body).to match('dull')
    end

    it "should censor attachments downloaded directly" do
      ir = info_requests(:fancy_dog_request)

      censor_rule = CensorRule.new
      censor_rule.text = "Second"
      censor_rule.replacement = "Mouse"
      censor_rule.last_edit_editor = "unknown"
      censor_rule.last_edit_comment = "none"
      ir.censor_rules << censor_rule

      begin
        receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

        get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt', :skip_cache => 1
        expect(response.content_type).to eq("text/plain")
        expect(response.body).to have_content "Mouse hello"
      ensure
        ir.censor_rules.clear
      end
    end

    it "should censor with rules on the user (rather than the request)" do
      ir = info_requests(:fancy_dog_request)

      censor_rule = CensorRule.new
      censor_rule.text = "Second"
      censor_rule.replacement = "Mouse"
      censor_rule.last_edit_editor = "unknown"
      censor_rule.last_edit_comment = "none"
      ir.user.censor_rules << censor_rule

      begin
        receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)
        ir.reload

        get :get_attachment, :incoming_message_id => ir.incoming_messages[1].id, :id => ir.id, :part => 2, :file_name => 'hello world.txt', :skip_cache => 1
        expect(response.content_type).to eq("text/plain")
        expect(response.body).to have_content "Mouse hello"
      ensure
        ir.user.censor_rules.clear
      end
    end

    it "should censor attachment names" do
      ir = info_requests(:fancy_dog_request)
      receive_incoming_mail('incoming-request-two-same-name.email', ir.incoming_email)

      # TODO: this is horrid, but don't know a better way.  If we
      # don't do this, the info_request_event to which the
      # info_request is attached still uses the unmodified
      # version from the fixture.
      #event = info_request_events(:useless_incoming_message_event)
      ir.reload
      assert ir.info_request_events[3].incoming_message.get_attachments_for_display.count == 2
      ir.save!
      ir.incoming_messages.last.save!
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      assert assigns[:info_request].info_request_events[3].incoming_message.get_attachments_for_display.count == 2
      # the issue is that the info_request_events have got cached on them the old info_requests.
      # where i'm at: trying to replace those fields that got re-read from the raw email.  however tests are failing in very strange ways.  currently I don't appear to be getting any attachments parsed in at all when in the template (see "*****" in _correspondence.html.erb) but do when I'm in the code.

      # so at this point, assigns[:info_request].incoming_messages[1].get_attachments_for_display is returning stuff, but the equivalent thing in the template isn't.
      # but something odd is that the above is return a whole load of attachments which aren't there in the controller
      expect(response.body).to have_css("p.attachment strong") do |s|
        expect(s).to contain /hello world.txt/m
      end

      censor_rule = CensorRule.new
      # Note that the censor rule applies to the original filename,
      # not the display_filename:
      censor_rule.text = "hello-world.txt"
      censor_rule.replacement = "goodbye.txt"
      censor_rule.last_edit_editor = "unknown"
      censor_rule.last_edit_comment = "none"
      ir.censor_rules << censor_rule
      begin
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        expect(response.body).to have_css("p.attachment strong") do |s|
          expect(s).to contain /goodbye.txt/m
        end
      ensure
        ir.censor_rules.clear
      end
    end


  end
end

describe RequestController, "when handling prominence" do

  def expect_hidden(hidden_template)
    expect(response.content_type).to eq("text/html")
    expect(response).to render_template(hidden_template)
    expect(response.code).to eq('403')
  end

  context 'when the request is hidden' do

    before(:each) do
      @info_request = FactoryGirl.create(:info_request_with_incoming_attachments,
                                         :prominence => 'hidden')
    end

    it "should not show request if you're not logged in" do
      get :show, :url_title => @info_request.url_title
      expect_hidden('hidden')
    end

    it "should not show request even if logged in as their owner" do
      session[:user_id] = @info_request.user.id
      get :show, :url_title => @info_request.url_title
      expect_hidden('hidden')
    end

    it 'should not show request if requested using json' do
      session[:user_id] = @info_request.user.id
      get :show, :url_title => @info_request.url_title, :format => 'json'
      expect(response.code).to eq('403')
    end

    it "should show request if logged in as super user" do
      session[:user_id] = FactoryGirl.create(:admin_user)
      get :show, :url_title => @info_request.url_title
      expect(response).to render_template('show')
    end

    it "should not download attachments" do
      incoming_message = @info_request.incoming_messages.first
      get :get_attachment, :incoming_message_id => incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect_hidden('request/hidden')
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryGirl.create(:admin_user)
      incoming_message = @info_request.incoming_messages.first
      expect do
        get :get_attachment_as_html, :incoming_message_id => incoming_message.id,
          :id => @info_request.id,
          :part => 2,
          :file_name => 'interesting.pdf'
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  context 'when the request is requester_only' do

    before(:each) do
      @info_request = FactoryGirl.create(:info_request_with_incoming_attachments,
                                         :prominence => 'requester_only')
    end

    it "should not show request if you're not logged in" do
      get :show, :url_title => @info_request.url_title
      expect_hidden('hidden')
    end

    it "should show request to requester and admin if logged in" do
      session[:user_id] = FactoryGirl.create(:user).id
      get :show, :url_title => @info_request.url_title
      expect_hidden('hidden')

      session[:user_id] = @info_request.user.id
      get :show, :url_title => @info_request.url_title
      expect(response).to render_template('show')

      session[:user_id] = FactoryGirl.create(:admin_user).id
      get :show, :url_title => @info_request.url_title
      expect(response).to render_template('show')
    end

    it 'should not cache an attachment when showing an attachment to the requester or admin' do
      session[:user_id] = @info_request.user.id
      incoming_message = @info_request.incoming_messages.first
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment, :incoming_message_id => incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf'
    end
  end

  context 'when the incoming message has prominence hidden' do

    before(:each) do
      @incoming_message = FactoryGirl.create(:incoming_message_with_attachments,
                                             :prominence => 'hidden')
      @info_request = @incoming_message.info_request
    end

    it "should not download attachments for a non-logged in user" do
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect_hidden('request/hidden_correspondence')
    end

    it 'should not download attachments for the request owner' do
      session[:user_id] = @info_request.user.id
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect_hidden('request/hidden_correspondence')
    end

    it 'should download attachments for an admin user' do
      session[:user_id] = FactoryGirl.create(:admin_user).id
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryGirl.create(:admin_user).id
      expect do
        get :get_attachment_as_html, :incoming_message_id => @incoming_message.id,
          :id => @info_request.id,
          :part => 2,
          :file_name => 'interesting.pdf',
          :skip_cache => 1
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not cache an attachment when showing an attachment to the requester or admin' do
      session[:user_id] = @info_request.user.id
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf'
    end

  end

  context 'when the incoming message has prominence requester_only' do

    before(:each) do
      @incoming_message = FactoryGirl.create(:incoming_message_with_attachments,
                                             :prominence => 'requester_only')
      @info_request = @incoming_message.info_request
    end

    it "should not download attachments for a non-logged in user" do
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect_hidden('request/hidden_correspondence')
    end

    it 'should download attachments for the request owner' do
      session[:user_id] = @info_request.user.id
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should download attachments for an admin user' do
      session[:user_id] = FactoryGirl.create(:admin_user).id
      get :get_attachment, :incoming_message_id => @incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf',
        :skip_cache => 1
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryGirl.create(:admin_user)
      expect do
        get :get_attachment_as_html, :incoming_message_id => @incoming_message.id,
          :id => @info_request.id,
          :part => 2,
          :file_name => 'interesting.pdf',
          :skip_cache => 1
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

end

# TODO: do this for invalid ids
#  it "should render 404 file" do
#    response.should render_template("#{Rails.root}/public/404.html")
#    response.headers["Status"].should == "404 Not Found"
#  end

describe RequestController, "when searching for an authority" do
  # Whether or not sign-in is required for this step is configurable,
  # so we make sure we're logged in, just in case
  before do
    @user = users(:bob_smith_user)
    get_fixtures_xapian_index
  end

  it "should return nothing for the empty query string" do
    session[:user_id] = @user.id
    get :select_authority, :query => ""

    expect(response).to render_template('select_authority')
    expect(assigns[:xapian_requests]).to eq(nil)
  end

  it "should return matching bodies" do
    session[:user_id] = @user.id
    get :select_authority, :query => "Quango"

    expect(response).to render_template('select_authority')
    assigns[:xapian_requests].results.size == 1
    expect(assigns[:xapian_requests].results[0][:model].name).to eq(public_bodies(:geraldine_public_body).name)
  end

  it "should not give an error when user users unintended search operators" do
    for phrase in ["Marketing/PR activities - Aldborough E-Act Free Schoo",
                   "Request for communications between DCMS/Ed Vaizey and ICO from Jan 1st 2011 - May ",
                   "Bellevue Road Ryde Isle of Wight PO33 2AR - what is the",
                   "NHS Ayrshire & Arran",
                   " cardiff",
                   "Foo * bax",
                   "qux ~ quux"]
      expect {
        get :select_authority, :query => phrase
      }.not_to raise_error
    end
  end

  it "remembers the search params" do
    session[:user_id] = @user.id
    search_params = {
      'query'  => 'Quango',
      'page'   => '1',
      'bodies' => '1'
    }

    get :select_authority, search_params

    expect(flash[:search_params]).to eq(search_params)
  end

end

describe RequestController, "when creating a new request" do
  render_views

  before do
    @user = users(:bob_smith_user)
    @body = public_bodies(:geraldine_public_body)
  end

  it "should redirect to front page if no public body specified" do
    get :new
    expect(response).to redirect_to(:controller => 'general', :action => 'frontpage')
  end

  it "should redirect to front page if no public body specified, when logged in" do
    session[:user_id] = @user.id
    get :new
    expect(response).to redirect_to(:controller => 'general', :action => 'frontpage')
  end

  it "should redirect 'bad request' page when a body has no email address" do
    @body.request_email = ""
    @body.save!
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new_bad_contact')
  end

  it "should accept a public body parameter" do
    get :new, :public_body_id => @body.id
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
  end

  it 'should display one meaningful error message when no message body is added' do
    post :new, :info_request => { :public_body_id => @body.id },
      :outgoing_message => { :body => "" },
      :submitted_new_request => 1, :preview => 1
    expect(assigns[:info_request].errors.full_messages).not_to include('Outgoing messages is invalid')
    expect(assigns[:outgoing_message].errors.full_messages).to include('Body Please enter your letter requesting information')
  end

  it "should give an error and render 'new' template when a summary isn't given" do
    post :new, :info_request => { :public_body_id => @body.id },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 1
    expect(assigns[:info_request].errors[:title]).not_to be_nil
    expect(response).to render_template('new')
  end

  it "should redirect to sign in page when input is good and nobody is logged in" do
    params = { :info_request => { :public_body_id => @body.id,
                                  :title => "Why is your quango called Geraldine?", :tag_string => "" },
               :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
               :submitted_new_request => 1, :preview => 0
               }
    post :new, params
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
    # post_redirect.post_params.should == params # TODO: get this working. there's a : vs '' problem amongst others
  end

  it 'redirects to the frontpage if the action is sent the invalid
        public_body param' do
    post :new, :info_request => { :public_body => @body.id,
                                  :title => 'Why Geraldine?',
    :tag_string => '' },
      :outgoing_message => { :body => 'This is a silly letter.' },
      :submitted_new_request => 1,
      :preview => 1
    expect(response).to redirect_to frontpage_url
  end

  it "should show preview when input is good" do
    session[:user_id] = @user.id
    post :new, { :info_request => { :public_body_id => @body.id,
                                    :title => "Why is your quango called Geraldine?", :tag_string => "" },
                 :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
                 :submitted_new_request => 1, :preview => 1
                 }
    expect(response).to render_template('preview')
  end

  it "should allow re-editing of a request" do
    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why is your quango called Geraldine?", :tag_string => "" },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 0,
      :reedit => "Re-edit this request"
    expect(response).to render_template('new')
  end

  it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
    session[:user_id] = @user.id
    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why is your quango called Geraldine?", :tag_string => "" },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 0

    ir_array = InfoRequest.find(:all, :conditions => ["title = ?", "Why is your quango called Geraldine?"])
    expect(ir_array.size).to eq(1)
    ir = ir_array[0]
    expect(ir.outgoing_messages.size).to eq(1)
    om = ir.outgoing_messages[0]
    expect(om.body).to eq("This is a silly letter. It is too short to be interesting.")

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/This is a silly letter. It is too short to be interesting./)

    expect(response).to redirect_to show_new_request_url(:url_title => ir.url_title)
    # This test uses an explicit path because it's relied in
    # Google Analytics goals:
    expect(response.redirect_url).to match(/request\/why_is_your_quango_called_gerald\/new$/)
  end

  it "sets the request_sent flash to true if successful" do
    session[:user_id] = @user.id
    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why is your quango called Geraldine?", :tag_string => "" },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 0

    expect(flash[:request_sent]).to be true
  end

  it "should give an error if the same request is submitted twice" do
    session[:user_id] = @user.id

    # We use raw_body here, so white space is the same
    post :new, :info_request => { :public_body_id => info_requests(:fancy_dog_request).public_body_id,
    :title => info_requests(:fancy_dog_request).title },
      :outgoing_message => { :body => info_requests(:fancy_dog_request).outgoing_messages[0].raw_body},
      :submitted_new_request => 1, :preview => 0, :mouse_house => 1
    expect(response).to render_template('new')
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
    expect(ir_array.size).to eq(2)

    ir = ir_array[0]
    ir2 = ir_array[1]

    expect(ir.url_title).not_to eq(ir2.url_title)

    expect(response).to redirect_to show_new_request_url(:url_title => ir2.url_title)
  end

  it 'should respect the rate limit' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    session[:user_id] = users(:robin_user)

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What is the answer to the ultimate question?", :tag_string => "" },
      :outgoing_message => { :body => "Please supply the answer from your files." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_new_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why did the chicken cross the road?", :tag_string => "" },
      :outgoing_message => { :body => "Please send me all the relevant documents you hold." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_new_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What's black and white and red all over?", :tag_string => "" },
      :outgoing_message => { :body => "Please send all minutes of meetings and email records that address this question." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to render_template('user/rate_limited')
  end

  it 'should ignore the rate limit for specified users' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    session[:user_id] = users(:robin_user)
    users(:robin_user).no_limit = true
    users(:robin_user).save!

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What is the answer to the ultimate question?", :tag_string => "" },
      :outgoing_message => { :body => "Please supply the answer from your files." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_new_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why did the chicken cross the road?", :tag_string => "" },
      :outgoing_message => { :body => "Please send me all the relevant documents you hold." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_new_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What's black and white and red all over?", :tag_string => "" },
      :outgoing_message => { :body => "Please send all minutes of meetings and email records that address this question." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_new_request_url(:url_title => 'whats_black_and_white_and_red_al')
  end

end

# These go with the previous set, but use mocks instead of fixtures.
# TODO harmonise these
describe RequestController, "when making a new request" do

  before do
    @user = mock_model(User, :id => 3481, :name => 'Testy')
    allow(@user).to receive(:get_undescribed_requests).and_return([])
    allow(@user).to receive(:can_leave_requests_undescribed?).and_return(false)
    allow(@user).to receive(:can_file_requests?).and_return(true)
    allow(@user).to receive(:locale).and_return("en")
    allow(User).to receive(:find).and_return(@user)

    @body = mock_model(PublicBody, :id => 314, :eir_only? => false, :is_requestable? => true, :name => "Test Quango")
    allow(PublicBody).to receive(:find).and_return(@body)
  end

  it "should allow you to have one undescribed request" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1 ])
    allow(@user).to receive(:can_leave_requests_undescribed?).and_return(false)
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new')
  end

  it "should fail if more than one request undescribed" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1, 2 ])
    allow(@user).to receive(:can_leave_requests_undescribed?).and_return(false)
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new_please_describe')
  end

  it "should allow you if more than one request undescribed but are allowed to leave requests undescribed" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1, 2 ])
    allow(@user).to receive(:can_leave_requests_undescribed?).and_return(true)
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new')
  end

  it "should fail if user is banned" do
    allow(@user).to receive(:can_file_requests?).and_return(false)
    allow(@user).to receive(:exceeded_limit?).and_return(false)
    expect(@user).to receive(:can_fail_html).and_return('FAIL!')
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('user/banned')
  end

end

describe RequestController, "when viewing an individual response for reply/followup" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should ask for login if you are logged in as wrong person" do
    session[:user_id] = users(:silly_name_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response).to render_template('user/wrong_user')
  end

  it "should show the response if you are logged in as right person" do
    session[:user_id] = users(:bob_smith_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response).to render_template('show_response')
  end

  it "should offer the opportunity to reply to the main address" do
    session[:user_id] = users(:bob_smith_user).id
    get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response.body).to have_css("div#other_recipients ul li", :text => "the main FOI contact address for")
  end

  it "should offer an opportunity to reply to another address" do
    session[:user_id] = users(:bob_smith_user).id
    ir = info_requests(:fancy_dog_request)
    ir.allow_new_responses_from = "anybody"
    ir.save!
    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "Frob <frob@bonce.com>")
    get :show_response, :id => ir.id, :incoming_message_id => incoming_messages(:useless_incoming_message)
    expect(response.body).to have_css("div#other_recipients ul li", :text => "Frob")
  end

  context 'when a request is hidden' do

    before do
      ir = info_requests(:fancy_dog_request)
      ir.prominence = 'hidden'
      ir.save!

      session[:user_id] = users(:bob_smith_user).id
    end

    it "should not show individual responses, even if request owner" do
      get :show_response, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message)
      expect(response).to render_template('request/hidden')
    end

    it 'should respond to a json request for a hidden request with a 403 code and no body' do
      get :show_response, :id => info_requests(:fancy_dog_request).id,
        :incoming_message_id => incoming_messages(:useless_incoming_message),
        :format => 'json'

      expect(response.code).to eq('403')
    end

  end

  describe 'when viewing a response for an external request' do

    it 'should show a message saying that external requests cannot be followed up' do
      get :show_response, :id => info_requests(:external_request).id
      expect(response).to render_template('request/followup_bad')
      expect(assigns[:reason]).to eq('external')
    end

    it 'should be successful' do
      get :show_response, :id => info_requests(:external_request).id
      expect(response).to be_success
    end

  end

end

describe RequestController, "when classifying an information request" do

  describe 'if the request is external' do

    before do
      @external_request = info_requests(:external_request)
    end

    it 'should redirect to the request page' do
      post :describe_state, :id => @external_request.id
      expect(response).to redirect_to(:action => 'show',
                                  :controller => 'request',
                                  :url_title => @external_request.url_title)
    end

  end

  describe 'when the request is internal' do

    before(:each) do
      @dog_request = info_requests(:fancy_dog_request)
      allow(@dog_request).to receive(:is_old_unclassified?).and_return(false)
      allow(InfoRequest).to receive(:find).and_return(@dog_request)
      load_raw_emails_data
    end

    def post_status(status)
      post :describe_state, :incoming_message => { :described_state => status },
        :id => @dog_request.id,
        :last_info_request_event_id => @dog_request.last_event_id_needing_description
    end

    it "should require login" do
      post_status('rejected')
      expect(response).to redirect_to(:controller => 'user',
                                      :action => 'signin',
                                      :token => get_last_post_redirect.token)
    end

    it 'should ask whether the request is old and unclassified' do
      session[:user_id] = users(:silly_name_user).id
      expect(@dog_request).to receive(:is_old_unclassified?)
      post_status('rejected')
    end

    it "should not classify the request if logged in as the wrong user" do
      session[:user_id] = users(:silly_name_user).id
      post_status('rejected')
      expect(response).to render_template('user/wrong_user')
    end

    describe 'when the request is old and unclassified' do

      before do
        allow(@dog_request).to receive(:is_old_unclassified?).and_return(true)
        mail_mock = double("mail")
        allow(mail_mock).to receive(:deliver)
        allow(RequestMailer).to receive(:old_unclassified_updated).and_return(mail_mock)
      end

      describe 'when the user is not logged in' do

        it 'should require login' do
          session[:user_id] = nil
          post_status('rejected')
          expect(response).to redirect_to(:controller => 'user',
                                          :action => 'signin',
                                          :token => get_last_post_redirect.token)
        end

      end

      describe 'when the user is logged in as a different user' do

        before do
          @other_user = mock_model(User)
          session[:user_id] = users(:silly_name_user).id
        end

        it 'should classify the request' do
          allow(@dog_request).to receive(:calculate_status).and_return('rejected')
          expect(@dog_request).to receive(:set_described_state).with('rejected', users(:silly_name_user), nil)
          post_status('rejected')
        end

        it 'should log a status update event' do
          expected_params = {:user_id => users(:silly_name_user).id,
                             :old_described_state => 'waiting_response',
                             :described_state => 'rejected'}
          event = mock_model(InfoRequestEvent)
          expect(@dog_request).to receive(:log_event).with("status_update", expected_params).and_return(event)
          post_status('rejected')
        end

        it 'should send an email to the requester letting them know someone has updated the status of their request' do
          expect(RequestMailer).to receive(:old_unclassified_updated)
          post_status('rejected')
        end

        it 'should redirect to the request page' do
          post_status('rejected')
          expect(response).to redirect_to(:action => 'show', :controller => 'request', :url_title => @dog_request.url_title)
        end

        it 'should show a message thanking the user for a good deed' do
          post_status('rejected')
          expect(flash[:notice]).to eq('Thank you for updating this request!')
        end

        context "playing the classification game" do
          before :each do
            session[:request_game] = true
          end

          it "should continue the game after classifying a request" do
            post_status("rejected")
            expect(flash[:notice]).to match(/There are some more requests below for you to classify/)
            expect(response).to redirect_to categorise_play_url
          end
        end

        it "should send a mail from the user who changed the state to requires_admin" do
          post :describe_state, :incoming_message => { :described_state => "requires_admin", :message => "a message" }, :id => @dog_request.id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => @dog_request.last_event_id_needing_description

          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(1)
          mail = deliveries[0]
          expect(mail.from_addrs.first.to_s).to eq(users(:silly_name_user).email)
        end
      end
    end

    describe 'when logged in as an admin user who is not the actual requester' do

      before do
        @admin_user = users(:admin_user)
        session[:user_id] = @admin_user.id
        @dog_request = info_requests(:fancy_dog_request)
        allow(InfoRequest).to receive(:find).and_return(@dog_request)
        allow(@dog_request).to receive(:each).and_return([@dog_request])
      end

      it 'should update the status of the request' do
        allow(@dog_request).to receive(:calculate_status).and_return('rejected')
        expect(@dog_request).to receive(:set_described_state).with('rejected', @admin_user, nil)
        post_status('rejected')
      end

      it 'should log a status update event' do
        event = mock_model(InfoRequestEvent)
        expected_params = {:user_id => @admin_user.id,
                           :old_described_state => 'waiting_response',
                           :described_state => 'rejected'}
        expect(@dog_request).to receive(:log_event).with("status_update", expected_params).and_return(event)
        post_status('rejected')
      end

      it 'should record a classification' do
        event = mock_model(InfoRequestEvent)
        allow(@dog_request).to receive(:log_event).with("status_update", anything).and_return(event)
        expect(RequestClassification).to receive(:create!).with(:user_id => @admin_user.id,
                                                            :info_request_event_id => event.id)
        post_status('rejected')
      end

      it 'should send an email to the requester letting them know someone has updated the status of their request' do
        mail_mock = double("mail")
        allow(mail_mock).to receive :deliver
        expect(RequestMailer).to receive(:old_unclassified_updated).and_return(mail_mock)
        post_status('rejected')
      end

      it 'should redirect to the request page' do
        post_status('rejected')
        expect(response).to redirect_to(:action => 'show', :controller => 'request', :url_title => @dog_request.url_title)
      end

      it 'should show a message thanking the user for a good deed' do
        post_status('rejected')
        expect(flash[:notice]).to eq('Thank you for updating this request!')
      end
    end

    describe 'when logged in as an admin user who is also the actual requester' do

      before do
        @admin_user = users(:admin_user)
        session[:user_id] = @admin_user.id
        @dog_request = info_requests(:fancy_dog_request)
        @dog_request.user = @admin_user
        @dog_request.save!
        allow(InfoRequest).to receive(:find).and_return(@dog_request)
        allow(@dog_request).to receive(:each).and_return([@dog_request])
      end

      it 'should update the status of the request' do
        allow(@dog_request).to receive(:calculate_status).and_return('rejected')
        expect(@dog_request).to receive(:set_described_state).with('rejected', @admin_user, nil)
        post_status('rejected')
      end

      it 'should log a status update event' do
        expect(@dog_request).to receive(:log_event)
        post_status('rejected')
      end

      it 'should not send an email to the requester letting them know someone has updated the status of their request' do
        expect(RequestMailer).not_to receive(:old_unclassified_updated)
        post_status('rejected')
      end

      it 'should say it is showing advice as to what to do next' do
        post_status('rejected')
        expect(flash[:notice]).to match(/Here is what to do now/)
      end

      it 'should redirect to the unhappy page' do
        post_status('rejected')
        expect(response).to redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
      end

    end

    describe 'when logged in as the requestor' do

      before do
        @request_owner = users(:bob_smith_user)
        session[:user_id] = @request_owner.id
        expect(@dog_request.awaiting_description).to eq(true)
        allow(@dog_request).to receive(:each).and_return([@dog_request])
      end

      it "should let you know when you forget to select a status" do
        post :describe_state, :id => @dog_request.id,
          :last_info_request_event_id => @dog_request.last_event_id_needing_description
        expect(response).to redirect_to show_request_url(:url_title => @dog_request.url_title)
        expect(flash[:error]).to eq(_("Please choose whether or not you got some of the information that you wanted."))
      end

      it "should not change the status if the request has changed while viewing it" do
        allow(@dog_request).to receive(:last_event_id_needing_description).and_return(2)

        post :describe_state, :incoming_message => { :described_state => "rejected" },
          :id => @dog_request.id, :last_info_request_event_id => 1
        expect(response).to redirect_to show_request_url(:url_title => @dog_request.url_title)
        expect(flash[:error]).to match(/The request has been updated since you originally loaded this page/)
      end

      it "should successfully classify response if logged in as user controlling request" do
        post_status('rejected')
        expect(response).to redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
        @dog_request.reload
        expect(@dog_request.awaiting_description).to eq(false)
        expect(@dog_request.described_state).to eq('rejected')
        expect(@dog_request.get_last_public_response_event).to eq(info_request_events(:useless_incoming_message_event))
        expect(@dog_request.info_request_events.last.event_type).to eq("status_update")
        expect(@dog_request.info_request_events.last.calculated_state).to eq('rejected')
      end

      it 'should log a status update event' do
        expect(@dog_request).to receive(:log_event)
        post_status('rejected')
      end

      it 'should not send an email to the requester letting them know someone has updated the status of their request' do
        expect(RequestMailer).not_to receive(:old_unclassified_updated)
        post_status('rejected')
      end

      it "should go to the page asking for more information when classified as requires_admin" do
        post :describe_state, :incoming_message => { :described_state => "requires_admin" }, :id => @dog_request.id, :incoming_message_id => incoming_messages(:useless_incoming_message), :last_info_request_event_id => @dog_request.last_event_id_needing_description
        expect(response).to redirect_to describe_state_message_url(:url_title => @dog_request.url_title, :described_state => "requires_admin")

        @dog_request.reload
        expect(@dog_request.described_state).not_to eq('requires_admin')

        expect(ActionMailer::Base.deliveries).to be_empty
      end

      context "message is included when classifying as requires_admin" do
        it "should send an email including the message" do
          post :describe_state,
          :incoming_message => {
            :described_state => "requires_admin",
          :message => "Something weird happened" },
            :id => @dog_request.id,
            :last_info_request_event_id => @dog_request.last_event_id_needing_description

          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.size).to eq(1)
          mail = deliveries[0]
          expect(mail.body).to match(/as needing admin/)
          expect(mail.body).to match(/Something weird happened/)
        end
      end


      it 'should say it is showing advice as to what to do next' do
        post_status('rejected')
        expect(flash[:notice]).to match(/Here is what to do now/)
      end

      it 'should redirect to the unhappy page' do
        post_status('rejected')
        expect(response).to redirect_to(:controller => 'help', :action => 'unhappy', :url_title => @dog_request.url_title)
      end

      it "knows about extended states" do
        InfoRequest.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
        InfoRequest.send(:include, InfoRequestCustomStates)
        InfoRequest.class_eval('@@custom_states_loaded = true')
        RequestController.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
        RequestController.send(:include, RequestControllerCustomStates)
        RequestController.class_eval('@@custom_states_loaded = true')
        allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 10, 00, 01))
        post_status('deadline_extended')
        expect(flash[:notice]).to eq('Authority has requested extension of the deadline.')
      end
    end

    describe 'after a successful status update by the request owner' do

      before do
        @request_owner = users(:bob_smith_user)
        session[:user_id] = @request_owner.id
        @dog_request = info_requests(:fancy_dog_request)
        allow(@dog_request).to receive(:each).and_return([@dog_request])
        allow(InfoRequest).to receive(:find).and_return(@dog_request)
      end

      def request_url
        "request/#{@dog_request.url_title}"
      end

      def unhappy_url
        "help/unhappy/#{@dog_request.url_title}"
      end

      def expect_redirect(status, redirect_path)
        post_status(status)
        expect(response).to redirect_to("http://test.host/#{redirect_path}")
      end

      context 'when status is updated to "waiting_response"' do

        it 'should redirect to the "request url" with a message in the right tense when
                    the response is not overdue' do
          allow(@dog_request).to receive(:date_response_required_by).and_return(Time.now.to_date+1)
          allow(@dog_request).to receive(:date_very_overdue_after).and_return(Time.now.to_date+40)

          expect_redirect("waiting_response", "request/#{@dog_request.url_title}")
          expect(flash[:notice]).to match(/should get a response/)
        end

        it 'should redirect to the "request url" with a message in the right tense when
                    the response is overdue' do
          allow(@dog_request).to receive(:date_response_required_by).and_return(Time.now.to_date-1)
          allow(@dog_request).to receive(:date_very_overdue_after).and_return(Time.now.to_date+40)
          expect_redirect('waiting_response', request_url)
          expect(flash[:notice]).to match(/should have got a response/)
        end

        it 'should redirect to the "request url" with a message in the right tense when
                    the response is overdue' do
          allow(@dog_request).to receive(:date_response_required_by).and_return(Time.now.to_date-2)
          allow(@dog_request).to receive(:date_very_overdue_after).and_return(Time.now.to_date-1)
          expect_redirect('waiting_response', unhappy_url)
          expect(flash[:notice]).to match(/is long overdue/)
          expect(flash[:notice]).to match(/by more than 40 working days/)
          expect(flash[:notice]).to match(/within 20 working days/)
        end
      end

      context 'when status is updated to "not held"' do

        it 'should redirect to the "request url"' do
          expect_redirect('not_held', request_url)
        end

      end

      context 'when status is updated to "successful"' do

        it 'should redirect to the "request url"' do
          expect_redirect('successful', request_url)
        end

        it 'should show a message including the donation url if there is one' do
          allow(AlaveteliConfiguration).to receive(:donation_url).and_return('http://donations.example.com')
          post_status('successful')
          expect(flash[:notice]).to match('make a donation')
          expect(flash[:notice]).to match('http://donations.example.com')
        end

        it 'should show a message without reference to donations if there is no
                    donation url' do
          allow(AlaveteliConfiguration).to receive(:donation_url).and_return('')
          post_status('successful')
          expect(flash[:notice]).not_to match('make a donation')
        end

      end

      context 'when status is updated to "waiting clarification"' do

        it 'should redirect to the "response url" when there is a last response' do
          incoming_message = mock_model(IncomingMessage)
          allow(@dog_request).to receive(:get_last_public_response).and_return(incoming_message)
          expect_redirect('waiting_clarification', "request/#{@dog_request.id}/response/#{incoming_message.id}")
        end

        it 'should redirect to the "response no followup url" when there are no events
                    needing description' do
          allow(@dog_request).to receive(:get_last_public_response).and_return(nil)
          expect_redirect('waiting_clarification', "request/#{@dog_request.id}/response")
        end

      end

      context 'when status is updated to "rejected"' do

        it 'should redirect to the "unhappy url"' do
          expect_redirect('rejected', "help/unhappy/#{@dog_request.url_title}")
        end

      end

      context 'when status is updated to "partially successful"' do

        it 'should redirect to the "unhappy url"' do
          expect_redirect('partially_successful', "help/unhappy/#{@dog_request.url_title}")
        end

        it 'should show a message including the donation url if there is one' do
          allow(AlaveteliConfiguration).to receive(:donation_url).and_return('http://donations.example.com')
          post_status('successful')
          expect(flash[:notice]).to match('make a donation')
          expect(flash[:notice]).to match('http://donations.example.com')
        end

        it 'should show a message without reference to donations if there is no
                    donation url' do
          allow(AlaveteliConfiguration).to receive(:donation_url).and_return('')
          post_status('successful')
          expect(flash[:notice]).not_to match('make a donation')
        end

      end

      context 'when status is updated to "gone postal"' do

        it 'should redirect to the "respond to last url"' do
          expect_redirect('gone_postal', "request/#{@dog_request.id}/response/#{@dog_request.get_last_public_response.id}?gone_postal=1")
        end

      end

      context 'when status updated to "internal review"' do

        it 'should redirect to the "request url"' do
          expect_redirect('internal_review', request_url)
        end

      end

      context 'when status is updated to "requires admin"' do

        it 'should redirect to the "request url"' do
          post :describe_state, :incoming_message => {
            :described_state => 'requires_admin',
          :message => "A message" },
            :id => @dog_request.id,
            :last_info_request_event_id => @dog_request.last_event_id_needing_description
          expect(response).to redirect_to show_request_url(:url_title => @dog_request.url_title)
        end

      end

      context 'when status is updated to "error message"' do

        it 'should redirect to the "request url"' do
          post :describe_state, :incoming_message => {
            :described_state => 'error_message',
          :message => "A message" },
            :id => @dog_request.id,
            :last_info_request_event_id => @dog_request.last_event_id_needing_description
          expect(response).to redirect_to show_request_url(:url_title => @dog_request.url_title)
        end

      end

      context 'when status is updated to "user_withdrawn"' do

        it 'should redirect to the "respond to last url url" ' do
          expect_redirect('user_withdrawn', "request/#{@dog_request.id}/response/#{@dog_request.get_last_public_response.id}")
        end

      end
    end

  end

end

describe RequestController, "when sending a followup message" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should require login" do
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).to redirect_to(:controller => 'user',
                                    :action => 'signin',
                                    :token => get_last_post_redirect.token)
  end

  it "should not let you if you are logged in as the wrong user" do
    session[:user_id] = users(:silly_name_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).to render_template('user/wrong_user')
  end

  it "should give an error and render 'show_response' template when a body isn't given" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1

    # TODO: how do I check the error message here?
    expect(response).to render_template('show_response')
  end

  it "should show preview when input is good" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 1
    expect(response).to render_template('followup_preview')
  end

  it "should allow re-editing of a preview" do
    session[:user_id] = users(:bob_smith_user).id
    post :show_response, :outgoing_message => { :body => "What a useless response! You suck.", :what_doing => 'normal_sort'}, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1, :preview => 0, :reedit => "Re-edit this request"
    expect(response).to render_template('show_response')
  end

  it "should send the follow up message if you are the right user" do
    # fake that this is a clarification
    info_requests(:fancy_dog_request).set_described_state('waiting_clarification')
    expect(info_requests(:fancy_dog_request).described_state).to eq('waiting_clarification')
    expect(info_requests(:fancy_dog_request).get_last_public_response_event.calculated_state).to eq('waiting_clarification')

    # make the followup
    session[:user_id] = users(:bob_smith_user).id

    post :show_response,
    :outgoing_message => {
      :body => "What a useless response! You suck.",
      :what_doing => 'normal_sort'
    },
      :id => info_requests(:fancy_dog_request).id,
      :incoming_message_id => incoming_messages(:useless_incoming_message),
      :submitted_followup => 1

    # check it worked
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/What a useless response! You suck./)
    expect(mail.to_addrs.first.to_s).to eq("foiperson@localhost")

    expect(response).to redirect_to(:action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)

    # and that the status changed
    info_requests(:fancy_dog_request).reload
    expect(info_requests(:fancy_dog_request).described_state).to eq('waiting_response')
    expect(info_requests(:fancy_dog_request).get_last_public_response_event.calculated_state).to eq('waiting_clarification')
  end

  it "should give an error if the same followup is submitted twice" do
    session[:user_id] = users(:bob_smith_user).id

    # make the followup once
    post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    expect(response).to redirect_to(:action => 'show', :url_title => info_requests(:fancy_dog_request).url_title)

    # second time should give an error
    post :show_response, :outgoing_message => { :body => "Stop repeating yourself!", :what_doing => 'normal_sort' }, :id => info_requests(:fancy_dog_request).id, :incoming_message_id => incoming_messages(:useless_incoming_message), :submitted_followup => 1
    # TODO: how do I check the error message here?
    expect(response).to render_template('show_response')
  end

end

# TODO: Stuff after here should probably be in request_mailer_spec.rb - but then
# it can't check the URLs in the emails I don't think, ugh.

describe RequestController, "sending overdue request alerts" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should send an overdue alert mail to creators of overdue requests" do
    chicken_request = info_requests(:naughty_chicken_request)
    chicken_request.outgoing_messages[0].last_sent_at = Time.now - 30.days
    chicken_request.outgoing_messages[0].save!

    RequestMailer.alert_overdue_requests

    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)
    mail = chicken_mails[0]

    expect(mail.body).to match(/promptly, as normally/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:naughty_chicken_request).user.email)

    mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
    mail_url = $1
    mail_token = $2

    expect(session[:user_id]).to be_nil
    controller.test_code_redirect_by_email_token(mail_token, self) # TODO: hack to avoid having to call User controller for email link
    expect(session[:user_id]).to eq(info_requests(:naughty_chicken_request).user.id)

    expect(response).to render_template('show_response')
    expect(assigns[:info_request]).to eq(info_requests(:naughty_chicken_request))
  end

  it "should include clause for schools when sending an overdue alert mail to creators of overdue requests" do
    chicken_request = info_requests(:naughty_chicken_request)
    chicken_request.outgoing_messages[0].last_sent_at = Time.now - 30.days
    chicken_request.outgoing_messages[0].save!

    chicken_request.public_body.tag_string = "school"
    chicken_request.public_body.save!

    RequestMailer.alert_overdue_requests

    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)
    mail = chicken_mails[0]

    expect(mail.body).to match(/promptly, as normally/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:naughty_chicken_request).user.email)
  end

  it "should send not actually send the overdue alert if the user is banned but should
        record it as sent" do
    user = info_requests(:naughty_chicken_request).user
    user.ban_text = 'Banned'
    user.save!
    expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to eq(0)
    RequestMailer.alert_overdue_requests

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
    expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to be > 0
  end

  it "should send a very overdue alert mail to creators of very overdue requests" do
    chicken_request = info_requests(:naughty_chicken_request)
    chicken_request.outgoing_messages[0].last_sent_at = Time.now - 60.days
    chicken_request.outgoing_messages[0].save!

    RequestMailer.alert_overdue_requests

    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)
    mail = chicken_mails[0]

    expect(mail.body).to match(/required by law/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:naughty_chicken_request).user.email)

    mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
    mail_url = $1
    mail_token = $2

    expect(session[:user_id]).to be_nil
    controller.test_code_redirect_by_email_token(mail_token, self) # TODO: hack to avoid having to call User controller for email link
    expect(session[:user_id]).to eq(info_requests(:naughty_chicken_request).user.id)

    expect(response).to render_template('show_response')
    expect(assigns[:info_request]).to eq(info_requests(:naughty_chicken_request))
  end

  it "should not resend alerts to people who've already received them" do
    chicken_request = info_requests(:naughty_chicken_request)
    chicken_request.outgoing_messages[0].last_sent_at = Time.now - 60.days
    chicken_request.outgoing_messages[0].save!
    RequestMailer.alert_overdue_requests
    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)
    RequestMailer.alert_overdue_requests
    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)
  end

  it 'should send alerts for requests where the last event forming the initial request is a followup
        being sent following a request for clarification' do
    chicken_request = info_requests(:naughty_chicken_request)
    chicken_request.outgoing_messages[0].last_sent_at = Time.now - 60.days
    chicken_request.outgoing_messages[0].save!
    RequestMailer.alert_overdue_requests
    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)

    # Request is waiting clarification
    chicken_request.set_described_state('waiting_clarification')

    # Followup message is sent
    outgoing_message = OutgoingMessage.new(:status => 'ready',
                                           :message_type => 'followup',
                                           :info_request_id => chicken_request.id,
                                           :body => 'Some text',
                                           :what_doing => 'normal_sort')

    outgoing_message.sendable?
    mail_message = OutgoingMailer.followup(
      outgoing_message.info_request,
      outgoing_message,
      outgoing_message.incoming_message_followup
    ).deliver
    outgoing_message.record_email_delivery(mail_message.to_addrs.join(', '), mail_message.message_id)

    outgoing_message.save!

    chicken_request = InfoRequest.find(chicken_request.id)

    # Last event forming the request is now the followup
    expect(chicken_request.last_event_forming_initial_request.event_type).to eq('followup_sent')

    # This isn't overdue, so no email
    RequestMailer.alert_overdue_requests
    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(1)

    # Make the followup older
    outgoing_message.last_sent_at = Time.now - 60.days
    outgoing_message.save!

    # Now it should be alerted on
    RequestMailer.alert_overdue_requests
    chicken_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /chickens/}
    expect(chicken_mails.size).to eq(2)
  end

end

describe RequestController, "sending unclassified new response reminder alerts" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should send an alert" do
    RequestMailer.alert_new_response_reminders

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(3) # sufficiently late it sends reminders too
    mail = deliveries[0]
    expect(mail.body).to match(/To let everyone know/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
    mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
    mail_url = $1
    mail_token = $2

    expect(session[:user_id]).to be_nil
    controller.test_code_redirect_by_email_token(mail_token, self) # TODO: hack to avoid having to call User controller for email link
    expect(session[:user_id]).to eq(info_requests(:fancy_dog_request).user.id)

    expect(response).to render_template('show')
    expect(assigns[:info_request]).to eq(info_requests(:fancy_dog_request))
    # TODO: should check anchor tag here :) that it goes to last new response
  end

end

describe RequestController, "clarification required alerts" do
  render_views
  before(:each) do
    load_raw_emails_data
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
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/asked you to explain/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
    mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
    mail_url = $1
    mail_token = $2

    expect(session[:user_id]).to be_nil
    controller.test_code_redirect_by_email_token(mail_token, self) # TODO: hack to avoid having to call User controller for email link
    expect(session[:user_id]).to eq(info_requests(:fancy_dog_request).user.id)

    expect(response).to render_template('show_response')
    expect(assigns[:info_request]).to eq(info_requests(:fancy_dog_request))
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
    expect(deliveries.size).to eq(0)
  end

end

describe RequestController, "comment alerts" do
  render_views
  before(:each) do
    load_raw_emails_data
  end

  it "should send an alert (once and once only)" do
    # delete fixture comment and make new one, so is in last month (as
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
    expect(mail.body).to match(/has annotated your/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
    mail.body.to_s =~ /(http:\/\/.*)/
    mail_url = $1
    expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{new_comment.id}")

    # check if we send again, no more go out
    deliveries.clear
    RequestMailer.alert_comment_on_request
    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it "should not send an alert when you comment on your own request" do
    # delete fixture comment and make new one, so is in last month (as
    # alerts are only for comments in last month, see
    # RequestMailer.alert_comment_on_request)
    existing_comment = info_requests(:fancy_dog_request).comments[0]
    existing_comment.info_request_events[0].destroy
    existing_comment.destroy
    new_comment = info_requests(:fancy_dog_request).add_comment('I also love making annotations.', users(:bob_smith_user))

    # try to send comment alert
    RequestMailer.alert_comment_on_request

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it 'should not send an alert for a comment on an external request' do
    external_request = info_requests(:external_request)
    external_request.add_comment("This external request is interesting", users(:silly_name_user))
    # try to send comment alert
    RequestMailer.alert_comment_on_request

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(0)
  end

  it "should send an alert when there are two new comments" do
    # add two comments - the second one sould be ignored, as is by the user who made the request.
    # the new comment here, will cause the one in the fixture to be picked up as a new comment by alert_comment_on_request also.
    new_comment = info_requests(:fancy_dog_request).add_comment('Not as daft as this one', users(:silly_name_user))
    new_comment = info_requests(:fancy_dog_request).add_comment('Or this one!!!', users(:bob_smith_user))

    RequestMailer.alert_comment_on_request

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/There are 2 new annotations/)
    expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
    mail.body.to_s =~ /(http:\/\/.*)/
    mail_url = $1
    expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{comments(:silly_comment).id}")

  end

end

describe RequestController, "when viewing comments" do
  render_views
  before(:each) do
    load_raw_emails_data
  end

  it "should link to the user who submitted it" do
    session[:user_id] = users(:bob_smith_user).id
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response.body).to have_css("div#comment-1 h2") do |s|
      expect(s).to contain /Silly.*left an annotation/m
      expect(s).not_to contain /You.*left an annotation/m
    end
  end

  it "should link to the user who submitted to it, even if it is you" do
    session[:user_id] = users(:silly_name_user).id
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response.body).to have_css("div#comment-1 h2") do |s|
      expect(s).to contain /Silly.*left an annotation/m
      expect(s).not_to contain /You.*left an annotation/m
    end
  end

end


describe RequestController, "authority uploads a response from the web interface" do
  render_views

  before(:each) do
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
    expect(@ir.public_body.is_foi_officer?(@normal_user)).to eq(false)
    session[:user_id] = @normal_user.id

    get :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response).to render_template('user/wrong_user')
  end

  it "should let you view upload form if you are an FOI officer" do
    @ir = info_requests(:fancy_dog_request)
    expect(@ir.public_body.is_foi_officer?(@foi_officer_user)).to eq(true)
    session[:user_id] = @foi_officer_user.id

    get :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog'
    expect(response).to render_template('request/upload_response')
  end

  it "should prevent uploads if you are not a requester" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.size
    session[:user_id] = @normal_user.id

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('/files/parrot.png','image/png')
    post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog',
      :body => "Find attached a picture of a parrot",
      :file_1 => parrot_upload,
      :submitted_upload_response => 1
    expect(response).to render_template('user/wrong_user')
  end

  it "should prevent entirely blank uploads" do
    session[:user_id] = @foi_officer_user.id

    post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog', :body => "", :submitted_upload_response => 1
    expect(response).to render_template('request/upload_response')
    expect(flash[:error]).to match(/Please type a message/)
  end

  it 'should 404 for non existent requests' do
    expect{ post :upload_response, :url_title => 'i_dont_exist'}.to raise_error(ActiveRecord::RecordNotFound)
  end

  # How do I test a file upload in rails?
  # http://stackoverflow.com/questions/1178587/how-do-i-test-a-file-upload-in-rails
  it "should let the authority upload a file" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.size
    session[:user_id] = @foi_officer_user.id

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('/files/parrot.png','image/png')
    post :upload_response, :url_title => 'why_do_you_have_such_a_fancy_dog',
      :body => "Find attached a picture of a parrot",
      :file_1 => parrot_upload,
      :submitted_upload_response => 1

    expect(response).to redirect_to(:action => 'show', :url_title => 'why_do_you_have_such_a_fancy_dog')
    expect(flash[:notice]).to match(/Thank you for responding to this FOI request/)

    # check there is a new attachment
    incoming_after = @ir.incoming_messages.size
    expect(incoming_after).to eq(incoming_before + 1)

    # check new attachment looks vaguely OK
    new_im = @ir.incoming_messages[-1]
    expect(new_im.mail.body).to match(/Find attached a picture of a parrot/)
    attachments = new_im.get_attachments_for_display
    expect(attachments.size).to eq(1)
    expect(attachments[0].filename).to eq("parrot.png")
    expect(attachments[0].display_size).to eq("94K")
  end
end

describe RequestController, "when showing JSON version for API" do
  before(:each) do
    load_raw_emails_data
  end

  it "should return data in JSON form" do
    get :show, :url_title => 'why_do_you_have_such_a_fancy_dog', :format => 'json'

    ir = JSON.parse(response.body)
    expect(ir.class.to_s).to eq('Hash')

    expect(ir['url_title']).to eq('why_do_you_have_such_a_fancy_dog')
    expect(ir['public_body']['url_name']).to eq('tgq')
    expect(ir['user']['url_name']).to eq('bob_smith')
  end

end

describe RequestController, "when doing type ahead searches" do
  render_views

  before :each do
    get_fixtures_xapian_index
  end

  it "should return nothing for the empty query string" do
    get :search_typeahead, :q => ""
    expect(response).to render_template('request/_search_ahead')
    expect(assigns[:xapian_requests]).to be_nil
  end

  it "should return a request matching the given keyword, but not users with a matching description" do
    get :search_typeahead, :q => "chicken"
    expect(response).to render_template('request/_search_ahead')
    expect(assigns[:xapian_requests].results.size).to eq(1)
    expect(assigns[:xapian_requests].results[0][:model].title).to eq(info_requests(:naughty_chicken_request).title)
  end

  it "should return all requests matching any of the given keywords" do
    get :search_typeahead, :q => "money dog"
    expect(response).to render_template('request/_search_ahead')
    expect(assigns[:xapian_requests].results.map{|x|x[:model].info_request}).to match_array([
      info_requests(:fancy_dog_request),
      info_requests(:naughty_chicken_request),
      info_requests(:another_boring_request),
    ])
  end

  it "should not return matches for short words" do
    get :search_typeahead, :q => "a"
    expect(response).to render_template('request/_search_ahead')
    expect(assigns[:xapian_requests]).to be_nil
  end

  it "should do partial matches for longer words" do
    get :search_typeahead, :q => "chick"
    expect(response).to render_template('request/_search_ahead')
    expect(assigns[:xapian_requests].results.size).to eq(1)
  end

  it "should not give an error when user users unintended search operators" do
    for phrase in ["Marketing/PR activities - Aldborough E-Act Free Schoo",
                   "Request for communications between DCMS/Ed Vaizey and ICO from Jan 1st 2011 - May ",
                   "Bellevue Road Ryde Isle of Wight PO33 2AR - what is the",
                   "NHS Ayrshire & Arran",
                   "uda ( units of dent",
                   "frob * baz",
                   "bar ~ qux"]
      expect {
        get :search_typeahead, :q => phrase
      }.not_to raise_error
    end
  end

  it "should return all requests matching any of the given keywords" do
    get :search_typeahead, :q => "dog -chicken"
    expect(assigns[:xapian_requests].results.size).to eq(1)
  end

  it 'can filter search results by public body' do
    get :search_typeahead, :q => 'boring', :requested_from => 'dfh'
    expect(assigns[:query]).to eq('requested_from:dfh boring')
  end

  it 'defaults to 25 results per page' do
    get :search_typeahead, :q => 'boring'
    expect(assigns[:per_page]).to eq(25)
  end

  it 'can limit the number of searches returned' do
    get :search_typeahead, :q => 'boring', :per_page => '1'
    expect(assigns[:per_page]).to eq(1)
    expect(assigns[:xapian_requests].results.size).to eq(1)
  end

end

describe RequestController, "when showing similar requests" do
  render_views

  before do
    get_fixtures_xapian_index
    load_raw_emails_data
  end

  it "should work" do
    get :similar, :url_title => info_requests(:badger_request).url_title
    expect(response).to render_template("request/similar")
    expect(assigns[:info_request]).to eq(info_requests(:badger_request))
  end

  it "should show similar requests" do
    badger_request = info_requests(:badger_request)
    get :similar, :url_title => badger_request.url_title

    # Xapian seems to think *all* the requests are similar
    expect(assigns[:xapian_object].results.map{|x|x[:model].info_request}).to match_array(InfoRequest.all.reject {|x| x == badger_request})
  end

  it "should 404 for non-existent paths" do
    expect {
      get :similar, :url_title => "there_is_really_no_such_path_owNAFkHR"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end


  it "should return 404 for pages we don't want to serve up" do
    badger_request = info_requests(:badger_request)
    expect {
      get :similar, :url_title => badger_request.url_title, :page => 100
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

end

describe RequestController, "when caching fragments" do
  it "should not fail with long filenames" do
    long_name = "blahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblah.txt"
    info_request = double(InfoRequest, :user_can_view? => true,
                        :all_can_view? => true)
    incoming_message = double(IncomingMessage, :info_request => info_request,
                            :parse_raw_email! => true,
                            :info_request_id => 132,
                            :id => 44,
                            :get_attachments_for_display => nil,
                            :apply_masks! => nil,
                            :user_can_view? => true,
                            :all_can_view? => true)
    attachment = FactoryGirl.build(:body_text, :filename => long_name)
    allow(IncomingMessage).to receive(:find).with("44").and_return(incoming_message)
    allow(IncomingMessage).to receive(:get_attachment_by_url_part_number_and_filename).and_return(attachment)
    allow(InfoRequest).to receive(:find).with("132").and_return(info_request)
    params = { :file_name => long_name,
               :controller => "request",
               :action => "get_attachment_as_html",
               :id => "132",
               :incoming_message_id => "44",
               :part => "2" }
    get :get_attachment_as_html, params
  end

end

describe RequestController, "#new_batch" do

  context "when batch requests is enabled" do

    before do
      allow(AlaveteliConfiguration).to receive(:allow_batch_requests).and_return(true)
    end

    context "when the current user can make batch requests" do

      before do
        @user = FactoryGirl.create(:user, :can_make_batch_requests => true)
        @public_body = FactoryGirl.create(:public_body)
        @other_public_body = FactoryGirl.create(:public_body)
        @public_body_ids = [@public_body.id, @other_public_body.id]
        @default_post_params = { :info_request => { :title => "What does it all mean?",
                                                    :tag_string => "" },
                                 :public_body_ids => @public_body_ids,
                                 :outgoing_message => { :body => "This is a silly letter." },
                                 :submitted_new_request => 1,
                                 :preview => 1 }
      end

      it 'should be successful' do
        get :new_batch, {:public_body_ids => @public_body_ids}, {:user_id => @user.id}
        expect(response).to be_success
      end

      it 'should render the "new" template' do
        get :new_batch, {:public_body_ids => @public_body_ids}, {:user_id => @user.id}
        expect(response).to render_template('request/new')
      end

      it 'should redirect to "select_authorities" if no public_body_ids param is passed' do
        get :new_batch, {}, {:user_id => @user.id}
        expect(response).to redirect_to select_authorities_path
      end

      it "should render 'preview' when given a good title and body" do
        post :new_batch, @default_post_params, { :user_id => @user.id }
        expect(response).to render_template('preview')
      end

      it "should give an error and render 'new' template when a summary isn't given" do
        @default_post_params[:info_request].delete(:title)
        post :new_batch, @default_post_params, { :user_id => @user.id }
        expect(assigns[:info_request].errors[:title]).to eq(['Please enter a summary of your request'])
        expect(response).to render_template('new')
      end

      it "should allow re-editing of a request" do
        params = @default_post_params.merge(:preview => 0, :reedit => 1)
        post :new_batch, params, { :user_id => @user.id }
        expect(response).to render_template('new')
      end

      context "on success" do

        def make_request
          @params = @default_post_params.merge(:preview => 0)
          post :new_batch, @params, { :user_id => @user.id }
        end

        it 'should create an info request batch and redirect to the new batch on success' do
          make_request
          new_info_request_batch = assigns[:info_request_batch]
          expect(new_info_request_batch).not_to be_nil
          expect(response).to redirect_to(info_request_batch_path(new_info_request_batch))
        end

        it 'should prevent double submission of a batch request' do
          make_request
          post :new_batch, @params, { :user_id => @user.id }
          expect(response).to render_template('new')
          expect(assigns[:existing_batch]).not_to be_nil
        end

        it 'sets the batch_sent flash to true' do
          make_request
          expect(flash[:batch_sent]).to be true
        end

      end

      context "when the user is banned" do

        before do
          @user.ban_text = "bad behaviour"
          @user.save!
        end

        it 'should show the "banned" template' do
          post :new_batch, @default_post_params, { :user_id => @user.id }
          expect(response).to render_template('user/banned')
          expect(assigns[:details]).to eq('bad behaviour')
        end

      end

    end

    context "when the current user can't make batch requests" do

      render_views

      before do
        @user = FactoryGirl.create(:user)
      end

      it 'should return a 403 with an appropriate message' do
        get :new_batch, {}, {:user_id => @user.id}
        expect(response.code).to eq('403')
        expect(response.body).to match("Users cannot usually make batch requests to multiple authorities at once")
      end

    end

    context 'when there is no logged-in user' do

      it 'should return a redirect to the login page' do
        get :new_batch
        expect(response).to redirect_to(:controller => 'user',
                                        :action => 'signin',
                                        :token => get_last_post_redirect.token)
      end
    end


  end

  context "when batch requests is not enabled" do

    it 'should return a 404' do
      allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)
      get :new_batch
      expect(response.code).to eq('404')
    end

  end

end

describe RequestController, "#select_authorities" do

  context "when batch requests is enabled" do

    before do
      get_fixtures_xapian_index
      load_raw_emails_data
      allow(AlaveteliConfiguration).to receive(:allow_batch_requests).and_return(true)
    end

    context "when the current user can make batch requests" do

      before do
        @user = FactoryGirl.create(:user, :can_make_batch_requests => true)
      end

      context 'when asked for HTML' do

        it 'should be successful' do
          get :select_authorities, {}, {:user_id => @user.id}
          expect(response).to be_success
        end

        it 'should render the "select_authorities" template' do
          get :select_authorities, {}, {:user_id => @user.id}
          expect(response).to render_template('request/select_authorities')
        end

        it 'should assign a list of search results to the view if passed a query' do
          get :select_authorities, {:public_body_query => "Quango"}, {:user_id => @user.id}
          expect(assigns[:search_bodies].results.size).to eq(1)
          expect(assigns[:search_bodies].results[0][:model].name).to eq(public_bodies(:geraldine_public_body).name)
        end

        it 'should assign a list of public bodies to the view if passed a list of ids' do
          get :select_authorities, {:public_body_ids => [public_bodies(:humpadink_public_body).id]},
            {:user_id => @user.id}
          expect(assigns[:public_bodies].size).to eq(1)
          expect(assigns[:public_bodies][0].name).to eq(public_bodies(:humpadink_public_body).name)
        end

        it 'should subtract a list of public bodies to remove from the list of bodies assigned to
                    the view' do
          get :select_authorities, {:public_body_ids => [public_bodies(:humpadink_public_body).id,
                                                         public_bodies(:geraldine_public_body).id],
          :remove_public_body_ids => [public_bodies(:geraldine_public_body).id]},
            {:user_id => @user.id}
          expect(assigns[:public_bodies].size).to eq(1)
          expect(assigns[:public_bodies][0].name).to eq(public_bodies(:humpadink_public_body).name)
        end

      end

      context 'when asked for JSON' do

        it 'should be successful' do
          get :select_authorities, {:public_body_query => "Quan", :format => 'json'}, {:user_id => @user.id}
          expect(response).to be_success
        end

        it 'should return a list of public body names and ids' do
          get :select_authorities, {:public_body_query => "Quan", :format => 'json'},
            {:user_id => @user.id}

          expect(JSON(response.body)).to eq([{ 'id' => public_bodies(:geraldine_public_body).id,
                                           'name' => public_bodies(:geraldine_public_body).name }])
        end

        it 'should return an empty list if no search is passed' do
          get :select_authorities, {:format => 'json' },{:user_id => @user.id}
          expect(JSON(response.body)).to eq([])
        end

        it 'should return an empty list if there are no bodies' do
          get :select_authorities, {:public_body_query => 'fknkskalnr', :format => 'json' },
            {:user_id => @user.id}
          expect(JSON(response.body)).to eq([])
        end

      end

    end

    context "when the current user can't make batch requests" do

      render_views

      before do
        @user = FactoryGirl.create(:user)
      end

      it 'should return a 403 with an appropriate message' do
        get :select_authorities, {}, {:user_id => @user.id}
        expect(response.code).to eq('403')
        expect(response.body).to match("Users cannot usually make batch requests to multiple authorities at once")
      end

    end

    context 'when there is no logged-in user' do

      it 'should return a redirect to the login page' do
        get :select_authorities
        expect(response).to redirect_to(:controller => 'user',
                                        :action => 'signin',
                                        :token => get_last_post_redirect.token)
      end
    end


  end

  context "when batch requests is not enabled" do

    it 'should return a 404' do
      allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)
      get :select_authorities
      expect(response.code).to eq('404')
    end

  end

end

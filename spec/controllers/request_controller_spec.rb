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

  it "returns 404 for non html requests" do
    get :list, :view => "all", :format => :json
    expect(response.status).to eq(404)
  end

  it 'should not raise an error for a page param of less than zero, but should treat it as
        a param of 1' do
    expect{ get :list, :view => 'all', :page => "-1" }.not_to raise_error
    expect(assigns[:page]).to eq(1)
  end

end

describe RequestController, "when changing things that appear on the request page" do

  before do
    PurgeRequest.destroy_all
  end

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
    outgoing = FactoryGirl.create(:outgoing_message, :info_request_id => ir.id,
                                                     :status => 'ready',
                                                     :message_type => 'followup',
                                                     :body => "What a useless response! You suck.",
                                                     :what_doing => 'normal_sort')
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
    expect(response.body).to have_css('ul.owner_actions')
  end

  describe 'when the request does allow comments' do
    it 'should have a comment link' do
      get :show, { :url_title => 'why_do_you_have_such_a_fancy_dog' },
        { :user_id => users(:admin_user).id }
      expect(response.body).to have_css('.anyone_actions', :text => "Add an annotation")
    end
  end

  describe 'when the request does not allow comments' do
    it 'should not have a comment link' do
      get :show, { :url_title => 'spam_1' },
        { :user_id => users(:admin_user).id }
      expect(response.body).not_to have_css('.anyone_actions', :text => "Add an annotation")
    end
  end

  context "when the request has not yet been reported" do
    it "should allow the user to report" do
      title = info_requests(:badger_request).url_title
      get :show, :url_title => title
      expect(response.body).to have_css('.anyone_actions a',
                                        :text => "Report this request")
    end

    it "does not show the request as having been reported" do
      title = info_requests(:badger_request).url_title
      get :show, :url_title => title
      expect(response.body).not_to have_content("This request has been reported")
    end
  end

  context "when the request has been reported for admin attention" do
    before :each do
      info_requests(:fancy_dog_request).report!("", "", nil)
    end

    it "should inform the user" do
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(response.body).to have_content("This request has been reported")
    end

    it "does not allow the request to be reported again" do
      get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
      expect(response.body).not_to have_css('.anyone_actions a',
                                            :text => "Report this request")
    end

    context "and then deemed okay and left to complete" do
      before :each do
        info_requests(:fancy_dog_request).set_described_state("successful")
      end

      it "does not allow the request to be reported again" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        expect(response.body).not_to have_css('.anyone_actions a',
                                              :text => "Report this request")
      end

      it "does not show the user the request has been reported message" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        expect(response.body).
          not_to have_content("This request has been reported")
      end

      it "should let the user know that the administrators have not hidden this request" do
        get :show, :url_title => 'why_do_you_have_such_a_fancy_dog'
        expect(response.body).to match(/the site administrators.*have not hidden it/)
      end
    end
  end

  it "should censor attachment names" do
    info_request = FactoryGirl.create(:info_request_with_html_attachment)
    get :show, :url_title => info_request.url_title
    expect(response.body).to have_css('.attachment .attachment__name') do |s|
      expect(s).to contain /interesting.pdf/m
    end
    # Note that the censor rule applies to the original filename,
    # not the display_filename:
    info_request.censor_rules.create!(:text => 'interesting.pdf',
                               :replacement => "Mouse.pdf",
                               :last_edit_editor => 'unknown',
                               :last_edit_comment => 'none')
    get :show, :url_title => info_request.url_title
    expect(response.body).to have_css('.attachment .attachment__name') do |s|
      expect(s).to contain /Mouse.pdf/m
    end
  end

  context 'when the request is embargoed' do
    it 'raises ActiveRecord::RecordNotFound' do
      embargoed_request = FactoryGirl.create(:embargoed_request)
      expect{ get :show, :url_title => embargoed_request.url_title }
        .to raise_error(ActiveRecord::RecordNotFound)
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
end

describe RequestController do
  describe 'GET get_attachment' do

    let(:info_request){ FactoryGirl.create(:info_request_with_incoming_attachments) }

    def get_attachment(params = {})
      default_params = { :incoming_message_id =>
                           info_request.incoming_messages.first.id,
                         :id => info_request.id,
                         :part => 2,
                         :file_name => 'interesting.pdf' }
      get :get_attachment, default_params.merge(params)
    end

    it 'should cache an attachment on a request with normal prominence' do
      expect(@controller).to receive(:foi_fragment_cache_write)
      get_attachment
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
      ugly_id = "55195"
      expect { get_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return 404 when incoming message and request ids
        don't match" do
      expect { get_attachment(:id => info_request.id + 1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return 404 for ugly URLs contain a request id that isn't an
        integer, even if the integer prefix refers to an actual request" do
      ugly_id = "#{FactoryGirl.create(:info_request).id}95"
      expect { get_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should redirect to the incoming message if there's a wrong part number
        and an ambiguous filename" do
      incoming_message = info_request.incoming_messages.first
      attachment = IncomingMessage.get_attachment_by_url_part_number_and_filename(
        incoming_message.get_attachments_for_display,
        5,
        'interesting.pdf'
      )
      expect(attachment).to be_nil
      get_attachment(:part => 5)
      expect(response.status).to eq(303)
      new_location = response.header['Location']
      expect(new_location)
        .to match incoming_message_path(incoming_message)
    end

    it "should find a uniquely named filename even if the URL part number was wrong" do
      info_request = FactoryGirl.create(:info_request_with_html_attachment)
      get :get_attachment, :incoming_message_id =>
                             info_request.incoming_messages.first.id,
                           :id => info_request.id,
                           :part => 5,
                           :file_name => 'interesting.html',
                           :skip_cache => 1
      expect(response.body).to match('dull')
    end

    it "should not download attachments with wrong file name" do
      info_request = FactoryGirl.create(:info_request_with_html_attachment)
      get :get_attachment, :incoming_message_id =>
                             info_request.incoming_messages.first.id,
                           :id => info_request.id,
                           :part => 2,
                           :file_name => 'http://trying.to.hack',
                           :skip_cache => 1
      expect(response.status).to eq(303)
    end

    it "should sanitise HTML attachments" do
      info_request = FactoryGirl.create(:info_request_with_html_attachment)
      get :get_attachment, :incoming_message_id =>
                              info_request.incoming_messages.first.id,
                           :id => info_request.id,
                           :part => 2,
                           :file_name => 'interesting.html',
                           :skip_cache => 1
      expect(response.body).not_to match("script")
      expect(response.body).not_to match("interesting")
      expect(response.body).to match('dull')
    end

    it "censors attachments downloaded directly" do
      info_request = FactoryGirl.create(:info_request_with_html_attachment)
      info_request.censor_rules.create!(:text => 'dull',
                                       :replacement => "Mouse",
                                       :last_edit_editor => 'unknown',
                                       :last_edit_comment => 'none')
      get :get_attachment, :incoming_message_id =>
                        info_request.incoming_messages.first.id,
                     :id => info_request.id,
                     :part => 2,
                     :file_name => 'interesting.html',
                     :skip_cache => 1
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Mouse"
    end

    it "should censor with rules on the user (rather than the request)" do
      info_request = FactoryGirl.create(:info_request_with_html_attachment)
      info_request.user.censor_rules.create!(:text => 'dull',
                                       :replacement => "Mouse",
                                       :last_edit_editor => 'unknown',
                                       :last_edit_comment => 'none')
      get :get_attachment, :incoming_message_id =>
                        info_request.incoming_messages.first.id,
                     :id => info_request.id,
                     :part => 2,
                     :file_name => 'interesting.html',
                     :skip_cache => 1
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Mouse"
    end

    it 'returns an ActiveRecord::RecordNotFound error for an embargoed request' do
      info_request = FactoryGirl.create(:embargoed_request)
      expect{ get :get_attachment, :incoming_message_id =>
                                    info_request.incoming_messages.first.id,
                                   :id => info_request.id,
                                   :part => 2,
                                   :file_name => 'interesting.pdf',
                                   :skip_cache => 1 }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end

describe RequestController do
  describe 'GET get_attachment_as_html' do
    let(:info_request){ FactoryGirl.create(:info_request_with_incoming_attachments) }

    def get_html_attachment(params = {})
      default_params = { :incoming_message_id =>
                           info_request.incoming_messages.first.id,
                         :id => info_request.id,
                         :part => 2,
                         :file_name => 'interesting.pdf.html' }
      get :get_attachment_as_html, default_params.merge(params)
    end

    it "should return 404 for ugly URLs containing a request id that isn't an integer" do
      ugly_id = "55195"
      expect { get_html_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return 404 for ugly URLs contain a request id that isn't an
        integer, even if the integer prefix refers to an actual request" do
      ugly_id = "#{FactoryGirl.create(:info_request).id}95"
      expect { get_html_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns an ActiveRecord::RecordNotFound error for an embargoed request' do
      info_request = FactoryGirl.create(:embargoed_request)
      expect{ get :get_attachment_as_html, :incoming_message_id =>
                                          info_request.incoming_messages.first.id,
                                        :id => info_request.id,
                                        :part => 2,
                                        :file_name => 'interesting.pdf.html' }
        .to raise_error ActiveRecord::RecordNotFound
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

    it "should not show request if logged in but not the requester" do
      session[:user_id] = FactoryGirl.create(:user).id
      get :show, :url_title => @info_request.url_title
      expect_hidden('hidden')
    end

    it "should show request to requester" do
      session[:user_id] = @info_request.user.id
      get :show, :url_title => @info_request.url_title
      expect(response).to render_template('show')
    end

    it "shouild show request to admin" do
      session[:user_id] = FactoryGirl.create(:admin_user).id
      get :show, :url_title => @info_request.url_title
      expect(response).to render_template('show')
    end

    it 'should not cache an attachment when showing an attachment to the requester' do
      session[:user_id] = @info_request.user.id
      incoming_message = @info_request.incoming_messages.first
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment, :incoming_message_id => incoming_message.id,
        :id => @info_request.id,
        :part => 2,
        :file_name => 'interesting.pdf'
    end

    it 'should not cache an attachment when showing an attachment to the admin' do
      session[:user_id] = FactoryGirl.create(:admin_user).id
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

  it 'assigns a default text for the request' do
    get :new, :public_body_id => @body.id
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
  end

  it 'allows the default text to be set via the default_letter param' do
    get :new, :url_name => @body.url_name, :default_letter => "test"
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    test

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
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

  it "re-editing preserves the message body" do
    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why is your quango called Geraldine?", :tag_string => "" },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 0,
      :reedit => "Re-edit this request"
    expect(assigns[:outgoing_message].body).
      to include('This is a silly letter. It is too short to be interesting.')
  end

  it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
    session[:user_id] = @user.id
    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why is your quango called Geraldine?", :tag_string => "" },
      :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
      :submitted_new_request => 1, :preview => 0

    ir_array = InfoRequest.where(:title => "Why is your quango called Geraldine?")
    expect(ir_array.size).to eq(1)
    ir = ir_array[0]
    expect(ir.outgoing_messages.size).to eq(1)
    om = ir.outgoing_messages[0]
    expect(om.body).to eq("This is a silly letter. It is too short to be interesting.")

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to eq(1)
    mail = deliveries[0]
    expect(mail.body).to match(/This is a silly letter. It is too short to be interesting./)

    expect(response).to redirect_to show_request_url(:url_title => ir.url_title)
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

    ir_array = InfoRequest.where(:title => "Why is your quango called Geraldine?").
                            order("id")
    expect(ir_array.size).to eq(2)

    ir = ir_array[0]
    ir2 = ir_array[1]

    expect(ir.url_title).not_to eq(ir2.url_title)

    expect(response).to redirect_to show_request_url(:url_title => ir2.url_title)
  end

  it 'should respect the rate limit' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    session[:user_id] = users(:robin_user)

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What is the answer to the ultimate question?", :tag_string => "" },
      :outgoing_message => { :body => "Please supply the answer from your files." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why did the chicken cross the road?", :tag_string => "" },
      :outgoing_message => { :body => "Please send me all the relevant documents you hold." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

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
    expect(response).to redirect_to show_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new, :info_request => { :public_body_id => @body.id,
    :title => "Why did the chicken cross the road?", :tag_string => "" },
      :outgoing_message => { :body => "Please send me all the relevant documents you hold." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

    post :new, :info_request => { :public_body_id => @body.id,
    :title => "What's black and white and red all over?", :tag_string => "" },
      :outgoing_message => { :body => "Please send all minutes of meetings and email records that address this question." },
      :submitted_new_request => 1, :preview => 0
    expect(response).to redirect_to show_request_url(:url_title => 'whats_black_and_white_and_red_al')
  end

  describe 'when rendering a reCAPTCHA' do

    context 'when new_request_recaptcha disabled' do

      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(false)
      end

      it 'sets render_recaptcha to false' do
        post :new, :info_request => { :public_body_id => @body.id,
          :title => "What's black and white and red all over?", :tag_string => "" },
          :outgoing_message => { :body => "Please send info" },
          :submitted_new_request => 1, :preview => 0
        expect(assigns[:render_recaptcha]).to eq(false)
      end
    end

    context 'when new_request_recaptcha is enabled' do

      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(true)
      end

      it 'sets render_recaptcha to true if there is no logged in user' do
        post :new, :info_request => { :public_body_id => @body.id,
          :title => "What's black and white and red all over?", :tag_string => "" },
          :outgoing_message => { :body => "Please send info" },
          :submitted_new_request => 1, :preview => 0
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to true if there is a logged in user who is not
            confirmed as not spam' do
        session[:user_id] = FactoryGirl.create(:user).id
        post :new, :info_request => { :public_body_id => @body.id,
          :title => "What's black and white and red all over?", :tag_string => "" },
          :outgoing_message => { :body => "Please send info" },
          :submitted_new_request => 1, :preview => 0
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to false if there is a logged in user who is
            confirmed as not spam' do
        session[:user_id] = FactoryGirl.create(:user,
                                               :confirmed_not_spam => true).id
        post :new, :info_request => { :public_body_id => @body.id,
          :title => "What's black and white and red all over?", :tag_string => "" },
          :outgoing_message => { :body => "Please send info" },
          :submitted_new_request => 1, :preview => 0
        expect(assigns[:render_recaptcha]).to eq(false)
      end

      context 'when the reCAPTCHA information is not correct' do

        before do
          allow(controller).to receive(:verify_recaptcha).and_return(false)
        end

        let(:user) { FactoryGirl.create(:user,
                                        :confirmed_not_spam => false) }
        let(:body) { FactoryGirl.create(:public_body) }

        it 'shows an error message' do
          session[:user_id] = user.id
          post :new, :info_request => { :public_body_id => body.id,
          :title => "Some request text", :tag_string => "" },
            :outgoing_message => { :body => "Please supply the answer from your files." },
            :submitted_new_request => 1, :preview => 0
          expect(flash[:error])
            .to eq("There was an error with the reCAPTCHA information - please try again.")
        end

        it 'renders the compose interface' do
          session[:user_id] = user.id
          post :new, :info_request => { :public_body_id => body.id,
          :title => "Some request text", :tag_string => "" },
            :outgoing_message => { :body => "Please supply the answer from your files." },
            :submitted_new_request => 1, :preview => 0
          expect(response).to render_template("new")
        end

        it 'allows the request if the user is confirmed not spam' do
          user.confirmed_not_spam = true
          user.save!
          session[:user_id] = user.id
          post :new, :info_request => { :public_body_id => body.id,
          :title => "Some request text", :tag_string => "" },
            :outgoing_message => { :body => "Please supply the answer from your files." },
            :submitted_new_request => 1, :preview => 0
          expect(response)
            .to redirect_to show_request_path(:url_title => 'some_request_text')
        end

      end

    end

  end

  describe 'when anti-spam is enabled' do

    before do
      allow(AlaveteliConfiguration).to receive(:enable_anti_spam)
        .and_return(true)
    end

    let(:user) { FactoryGirl.create(:user,
                                    :confirmed_not_spam => false) }
    let(:body) { FactoryGirl.create(:public_body) }

    context 'when the request subject line looks like spam' do

      it 'shows an error message' do
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(flash[:error])
          .to eq("Sorry, we're currently not able to send your request. Please try again later.")
      end

      it 'renders the compose interface' do
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(response)
          .to redirect_to show_request_path(:url_title => 'hd_watch_jason_bourne_online_fre')
      end

    end

    context 'when the request is from an IP address in a blocked country' do

      before do
        allow(AlaveteliConfiguration).to receive(:restricted_countries).and_return('PH')
        allow(controller).to receive(:country_from_ip).and_return('PH')
      end

      it 'shows an error message' do
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "Some request content", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(flash[:error])
          .to eq("Sorry, we're currently not able to send your request. Please try again later.")
      end

      it 'renders the compose interface' do
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "Some request content", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        session[:user_id] = user.id
        post :new, :info_request => { :public_body_id => body.id,
        :title => "Some request content", :tag_string => "" },
          :outgoing_message => { :body => "Please supply the answer from your files." },
          :submitted_new_request => 1, :preview => 0
        expect(response)
          .to redirect_to show_request_path(:url_title => 'some_request_content')
      end

    end

  end

end

# These go with the previous set, but use mocks instead of fixtures.
# TODO harmonise these
describe RequestController, "when making a new request" do

  before do
    @user = mock_model(User, :id => 3481, :name => 'Testy')
    allow(@user).to receive(:get_undescribed_requests).and_return([])
    allow(@user).to receive(:can_file_requests?).and_return(true)
    allow(@user).to receive(:locale).and_return("en")
    allow(User).to receive(:find).and_return(@user)
    @body = FactoryGirl.create(:public_body, :name => 'Test Quango')
  end

  it "should allow you to have one undescribed request" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1 ])
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new')
  end

  it "should fail if more than one request undescribed" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1, 2 ])
    session[:user_id] = @user.id
    get :new, :public_body_id => @body.id
    expect(response).to render_template('new_please_describe')
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

describe RequestController do
  describe "POST describe_state" do
    describe 'if the request is external' do

      let(:external_request){ FactoryGirl.create(:external_request) }

      it 'should redirect to the request page' do
        post :describe_state, :id => external_request.id
        expect(response)
          .to redirect_to(show_request_path(external_request.url_title))
      end

    end

    describe 'when the request is internal' do

      let(:info_request){ FactoryGirl.create(:info_request) }

      def post_status(status, info_request)
        post :describe_state, :incoming_message => { :described_state => status },
          :id => info_request.id,
          :last_info_request_event_id => info_request.last_event_id_needing_description
      end

      context 'when the request is embargoed' do

        let(:info_request){ FactoryGirl.create(:embargoed_request) }

        it 'should raise ActiveRecord::NotFound' do
          expect{ post_status('rejected', info_request) }
            .to raise_error ActiveRecord::RecordNotFound
        end
      end

      it "should require login" do
        post_status('rejected', info_request)
        expect(response).to redirect_to(:controller => 'user',
                                        :action => 'signin',
                                        :token => get_last_post_redirect.token)
      end

      it "should not classify the request if logged in as the wrong user" do
        session[:user_id] = FactoryGirl.create(:user).id
        post_status('rejected', info_request)
        expect(response).to render_template('user/wrong_user')
      end

      describe 'when the request is old and unclassified' do

        let(:info_request){ FactoryGirl.create(:old_unclassified_request)}

        describe 'when the user is not logged in' do

          it 'should require login' do
            session[:user_id] = nil
            post_status('rejected', info_request)
            expect(response)
              .to redirect_to(signin_path(:token => get_last_post_redirect.token))
          end

        end

        describe 'when the user is logged in as a different user' do

          let(:other_user){ FactoryGirl.create(:user) }

          before do
            session[:user_id] = other_user
          end

          it 'should classify the request' do
            post_status('rejected', info_request)
            expect(info_request.reload.described_state).to eq('rejected')
          end

          it 'should log a status update event' do
            expected_params = {:user_id => other_user.id,
                               :old_described_state => 'waiting_response',
                               :described_state => 'rejected'}
            post_status('rejected', info_request)
            last_event = info_request.reload.info_request_events.last
            expect(last_event.params).to eq expected_params
          end

          it 'should send an email to the requester letting them know someone
              has updated the status of their request' do
            post_status('rejected', info_request)
            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.size).to eq(1)
            expect(deliveries.first.subject)
              .to match("Someone has updated the status of your request")
          end

          it 'should redirect to the request page' do
            post_status('rejected', info_request)
            expect(response).to redirect_to(show_request_path(info_request.url_title))
          end

          it 'should show a message thanking the user for a good deed' do
            post_status('rejected', info_request)
            expect(flash[:notice]).to eq('Thank you for updating this request!')
          end

          context "playing the classification game" do
            before :each do
              session[:request_game] = true
            end

            it "should continue the game after classifying a request" do
              post_status("rejected", info_request)
              expect(flash[:notice]).to match(/There are some more requests below for you to classify/)
              expect(response).to redirect_to categorise_play_url
            end
          end

          context 'when the new status is "requires_admin"' do
            it "should send a mail to admins saying that the response requires admin
               and one to the requester noting the status change" do
              post :describe_state, :incoming_message =>
                                      { :described_state => "requires_admin",
                                        :message => "a message" },
                                    :id => info_request.id,
                                    :incoming_message_id =>
                                      info_request.incoming_messages.last,
                                    :last_info_request_event_id =>
                                      info_request.last_event_id_needing_description

              deliveries = ActionMailer::Base.deliveries
              expect(deliveries.size).to eq(2)
              requires_admin_mail = deliveries.first
              status_update_mail = deliveries.second
              expect(requires_admin_mail.subject)
                .to match(/FOI response requires admin/)
              expect(requires_admin_mail.to)
                .to match([AlaveteliConfiguration::contact_email])
              expect(status_update_mail.subject)
                .to match('Someone has updated the status of your request')
              expect(status_update_mail.to)
                .to match([info_request.user.email])
            end

            context "if the params don't include a message" do

              it 'redirects to the message url' do
                post :describe_state, :incoming_message =>
                                        { :described_state => "requires_admin" },
                                      :id => info_request.id,
                                      :incoming_message_id =>
                                        info_request.incoming_messages.last,
                                      :last_info_request_event_id =>
                                        info_request.last_event_id_needing_description
                expected_url = describe_state_message_url(
                                 :url_title => info_request.url_title,
                                 :described_state => 'requires_admin')
                expect(response).to redirect_to(expected_url)
              end

            end
          end
        end
      end

      describe 'when logged in as an admin user who is not the actual requester' do

        let(:admin_user){ FactoryGirl.create(:admin_user) }
        let(:info_request){ FactoryGirl.create(:info_request) }

        before do
          session[:user_id] = admin_user.id
        end

        it 'should update the status of the request' do
          post_status('rejected', info_request)
          expect(info_request.reload.described_state).to eq('rejected')
        end

        it 'should log a status update event' do
          expected_params = {:user_id => admin_user.id,
                             :old_described_state => 'waiting_response',
                             :described_state => 'rejected'}
          post_status('rejected', info_request)
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should record a classification' do
          post_status('rejected', info_request)
          last_event = info_request.reload.info_request_events.last
          classification = RequestClassification.order('created_at DESC').last
          expect(classification.user_id).to eq(admin_user.id)
          expect(classification.info_request_event).to eq(last_event)
        end

        it 'should send an email to the requester letting them know someone has
            updated the status of their request' do
          mail_mock = double("mail")
          allow(mail_mock).to receive :deliver
          expect(RequestMailer).to receive(:old_unclassified_updated).and_return(mail_mock)
          post_status('rejected', info_request)
        end

        it 'should redirect to the request page' do
          post_status('rejected', info_request)
          expect(response)
            .to redirect_to(show_request_path(info_request.url_title))
        end

        it 'should show a message thanking the user for a good deed' do
          post_status('rejected', info_request)
          expect(flash[:notice]).to eq('Thank you for updating this request!')
        end
      end

      describe 'when logged in as an admin user who is also the actual requester' do

        let(:admin_user){ FactoryGirl.create(:admin_user) }
        let(:info_request){ FactoryGirl.create(:info_request, :user => admin_user) }

        before do
          session[:user_id] = admin_user.id
        end

        it 'should update the status of the request' do
          post_status('rejected', info_request)
          expect(info_request.reload.described_state).to eq('rejected')
        end

        it 'should log a status update event' do
          expected_params = { :user_id => admin_user.id,
                              :old_described_state => 'waiting_response',
                              :described_state => 'rejected' }
          post_status('rejected', info_request)
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should not send an email to the requester letting them know someone
            has updated the status of their request' do
          expect(RequestMailer).not_to receive(:old_unclassified_updated)
          post_status('rejected', info_request)
        end

        it 'should show advice for the new state' do
          expect(controller)
            .to receive(:render_to_string)
              .with(:partial => 'request/describe_notices/rejected',
                    :locals => {:info_request => info_request})
                .and_return('')
          post_status('rejected', info_request)
        end

        it 'should redirect to the unhappy page' do
          post_status('rejected', info_request)
          expect(response)
            .to redirect_to(help_unhappy_path(info_request.url_title))
        end

      end

      describe 'when logged in as the requestor' do

        let(:info_request) do
          FactoryGirl.create(:info_request, :awaiting_description => true)
        end

        before do
          session[:user_id] = info_request.user_id
        end

        it "should let you know when you forget to select a status" do
          post :describe_state, :id => info_request.id,
                                :last_info_request_event_id =>
                                  info_request.last_event_id_needing_description
          expect(response).to redirect_to show_request_url(:url_title => info_request.url_title)
          expect(flash[:error])
            .to eq("Please choose whether or not you got some of the information that you wanted.")
        end

        it "should not change the status if the request has changed while viewing it" do
          post :describe_state, :incoming_message => { :described_state => "rejected" },
                                :id => info_request.id,
                                :last_info_request_event_id => 1
          expect(response)
            .to redirect_to show_request_url(:url_title => info_request.url_title)
          expect(flash[:error])
            .to match(/The request has been updated since you originally loaded this page/)
        end

        it "should successfully classify response" do
          post_status('rejected', info_request)
          expect(response)
            .to redirect_to(help_unhappy_path(info_request.url_title))
          info_request.reload
          expect(info_request.awaiting_description).to eq(false)
          expect(info_request.described_state).to eq('rejected')
          expect(info_request.info_request_events.last.event_type).to eq("status_update")
          expect(info_request.info_request_events.last.calculated_state).to eq('rejected')
        end

        it 'should log a status update event' do
          expected_params = {:user_id => info_request.user_id,
                             :old_described_state => 'waiting_response',
                             :described_state => 'rejected'}
          post_status('rejected', info_request)
          last_event = info_request.reload.info_request_events.last
          expect(last_event.params).to eq expected_params
        end

        it 'should not send an email to the requester letting them know someone
            has updated the status of their request' do
          expect(RequestMailer).not_to receive(:old_unclassified_updated)
          post_status('rejected', info_request)
        end

        it "should go to the page asking for more information when classified
            as requires_admin" do
          post :describe_state,
            :incoming_message => { :described_state => "requires_admin" },
            :id => info_request.id,
            :incoming_message_id => info_request.incoming_messages.last,
            :last_info_request_event_id => info_request.last_event_id_needing_description
          expect(response)
            .to redirect_to describe_state_message_url(:url_title => info_request.url_title,
                                                       :described_state => "requires_admin")

          info_request.reload
          expect(info_request.described_state).not_to eq('requires_admin')
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        context "message is included when classifying as requires_admin" do
          it "should send an email including the message" do
            post :describe_state,
            :incoming_message => {
              :described_state => "requires_admin",
            :message => "Something weird happened" },
              :id => info_request.id,
              :last_info_request_event_id => info_request.last_event_id_needing_description

            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.size).to eq(1)
            mail = deliveries[0]
            expect(mail.body).to match(/as needing admin/)
            expect(mail.body).to match(/Something weird happened/)
          end
        end

        it 'should show advice for the new state' do
          expect(controller)
            .to receive(:render_to_string)
              .with(:partial => 'request/describe_notices/rejected',
                    :locals => {:info_request => info_request})
                .and_return('')
          post_status('rejected', info_request)
        end

        it 'should redirect to the unhappy page' do
          post_status('rejected', info_request)
          expect(response).to redirect_to(help_unhappy_path(info_request.url_title))
        end

        it "knows about extended states" do
          InfoRequest.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
          InfoRequest.send(:include, InfoRequestCustomStates)
          InfoRequest.class_eval('@@custom_states_loaded = true')
          RequestController.send(:require, File.expand_path(File.join(File.dirname(__FILE__), '..', 'models', 'customstates')))
          RequestController.send(:include, RequestControllerCustomStates)
          RequestController.class_eval('@@custom_states_loaded = true')
          allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 10, 00, 01))
          post_status('deadline_extended', info_request)
          expect(flash[:notice]).to eq('Authority has requested extension of the deadline.')
        end
      end

      describe 'after a successful status update by the request owner' do

        render_views

        let(:info_request){ FactoryGirl.create(:info_request) }

        before do
          session[:user_id] = info_request.user_id
        end

        def expect_redirect(status, redirect_path)
          post_status(status, info_request)
          expect(response).
            to redirect_to("http://" + "test.host/#{redirect_path}".squeeze("/"))
        end

        context 'when status is updated to "waiting_response"' do

          it 'should redirect to the "request url" with a message in the right tense when
              the response is not overdue' do
            expect_redirect("waiting_response",
                            show_request_path(info_request.url_title))
            expect(flash[:notice]).to match(/should get a response/)
          end

          it 'should redirect to the "request url" with a message in the right tense when
              the response is overdue' do
            # Create the request with today's date
            info_request
            time_travel_to(1.month.from_now) do
              expect_redirect('waiting_response',
                              show_request_path(info_request.url_title))
              expect(flash[:notice]).to match(/should have got a response/)
            end
          end

          it 'should redirect to the "request url" with a message in the right tense when
              response is very overdue' do
            # Create the request with today's date
            info_request
            time_travel_to(2.month.from_now) do
              expect_redirect('waiting_response',
                              help_unhappy_path(info_request.url_title))
              expect(flash[:notice]).to match(/is long overdue/)
              expect(flash[:notice]).to match(/by more than 40 working days/)
              expect(flash[:notice]).to match(/within 20 working days/)
            end
          end
        end

        context 'when status is updated to "not held"' do

          it 'should redirect to the "request url"' do
            expect_redirect('not_held',
                            show_request_path(info_request.url_title))
          end

        end

        context 'when status is updated to "successful"' do

          it 'should redirect to the "request url"' do
            expect_redirect('successful',
                            show_request_path(info_request.url_title))
          end

          it 'should show a message including the donation url if there is one' do
            allow(AlaveteliConfiguration).to receive(:donation_url).and_return('http://donations.example.com')
            post_status('successful', info_request)
            expect(flash[:notice]).to match('make a donation')
            expect(flash[:notice]).to match('http://donations.example.com')
          end

          it 'should show a message without reference to donations if there is no
                      donation url' do
            allow(AlaveteliConfiguration).to receive(:donation_url).and_return('')
            post_status('successful', info_request)
            expect(flash[:notice]).not_to match('make a donation')
          end

        end

        context 'when status is updated to "waiting clarification"' do

          context 'when there is a last response' do

            let(:info_request){ FactoryGirl.create(:info_request_with_incoming) }

            it 'should redirect to the "response url"' do
              session[:user_id] = info_request.user_id
              expected_url = new_request_incoming_followup_path(
                              :request_id => info_request.id,
                              :incoming_message_id =>
                                info_request.get_last_public_response.id)
              expect_redirect('waiting_clarification', expected_url)
            end
          end

          context 'when there are no events needing description' do
            it 'should redirect to the "followup no incoming url"' do
              expected_url = new_request_followup_path(
                              :request_id => info_request.id,
                              :incoming_message_id => nil)
              expect_redirect('waiting_clarification', expected_url)
            end
          end

        end

        context 'when status is updated to "rejected"' do

          it 'should redirect to the "unhappy url"' do
            expect_redirect('rejected', help_unhappy_path(info_request.url_title))
          end

        end

        context 'when status is updated to "partially successful"' do

          it 'should redirect to the "unhappy url"' do
            expect_redirect('partially_successful',
                            help_unhappy_path(info_request.url_title))
          end

          it 'should show a message including the donation url if there is one' do
            allow(AlaveteliConfiguration).to receive(:donation_url).and_return('http://donations.example.com')
            post_status('successful', info_request)
            expect(flash[:notice]).to match('make a donation')
            expect(flash[:notice]).to match('http://donations.example.com')
          end

          it 'should show a message without reference to donations if there is no
                      donation url' do
            allow(AlaveteliConfiguration).to receive(:donation_url).and_return('')
            post_status('successful', info_request)
            expect(flash[:notice]).not_to match('make a donation')
          end

        end

        context 'when status is updated to "gone postal"' do

          let(:info_request){ FactoryGirl.create(:info_request_with_incoming) }

          it 'should redirect to the "respond to last" url' do
            session[:user_id] = info_request.user_id
            expected_url = new_request_incoming_followup_path(
                            :request_id => info_request.id,
                            :incoming_message_id =>
                              info_request.get_last_public_response.id,
                            :gone_postal => 1)
            expect_redirect('gone_postal', expected_url)
          end

        end

        context 'when status updated to "internal review"' do

          it 'should redirect to the "request url"' do
            expect_redirect('internal_review',
                            show_request_path(info_request.url_title))
          end

        end

        context 'when status is updated to "requires admin"' do

          it 'should redirect to the "request url"' do
            post :describe_state, :incoming_message => {
                :described_state => 'requires_admin',
                :message => "A message"
              },
              :id => info_request.id,
              :last_info_request_event_id =>
                info_request.last_event_id_needing_description
            expect(response)
              .to redirect_to show_request_url(:url_title => info_request.url_title)
          end

        end

        context 'when status is updated to "error message"' do

          it 'should redirect to the "request url"' do
            post :describe_state, :incoming_message => {
                :described_state => 'error_message',
                :message => "A message"
              },
              :id => info_request.id,
              :last_info_request_event_id =>
                info_request.last_event_id_needing_description
            expect(response)
              .to redirect_to(
                    show_request_url(:url_title => info_request.url_title)
                  )
          end

          context "if the params don't include a message" do

            it 'redirects to the message url' do
              post :describe_state, :incoming_message =>
                                      { :described_state => "error_message" },
                                    :id => info_request.id,
                                    :incoming_message_id =>
                                      info_request.incoming_messages.last,
                                    :last_info_request_event_id =>
                                      info_request.last_event_id_needing_description
              expected_url = describe_state_message_url(
                               :url_title => info_request.url_title,
                               :described_state => 'error_message')
              expect(response).to redirect_to(expected_url)
            end

          end

        end

        context 'when status is updated to "user_withdrawn"' do

          let(:info_request){ FactoryGirl.create(:info_request_with_incoming) }

          it 'should redirect to the "respond to last" url' do
            session[:user_id] = info_request.user_id
            expected_url = new_request_incoming_followup_path(
                            :request_id => info_request.id,
                            :incoming_message_id =>
                              info_request.get_last_public_response.id)
            expect_redirect('user_withdrawn', expected_url)
          end

        end

      end
    end
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

  context 'when the request is embargoed' do
    let(:embargoed_request){ FactoryGirl.create(:embargoed_request)}

    it 'raises an ActiveRecord::RecordNotFound error' do
      expect{get :upload_response, :url_title => embargoed_request.url_title }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

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

  before do
    get_fixtures_xapian_index
    load_raw_emails_data
  end

  let(:badger_request){ info_requests(:badger_request) }

  it "renders the 'similar' template" do
    get :similar, :url_title => info_requests(:badger_request).url_title
    expect(response).to render_template("request/similar")
  end

  it 'assigns the request' do
    get :similar, :url_title => info_requests(:badger_request).url_title
    expect(assigns[:info_request]).to eq(info_requests(:badger_request))
  end

  it "assigns a xapian object with similar requests" do
    get :similar, :url_title => badger_request.url_title

    # Xapian seems to think *all* the requests are similar
    results = assigns[:xapian_object].results
    expected = InfoRequest.all.reject{ |request| request == badger_request }
    expect(results.map{ |result| result[:model].info_request })
      .to match_array(expected)
  end

  it "raises ActiveRecord::RecordNotFound for non-existent paths" do
    expect {
      get :similar, :url_title => "there_is_really_no_such_path_owNAFkHR"
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises ActiveRecord::RecordNotFound for pages beyond the last
      page we want to show" do
    expect {
      get :similar, :url_title => badger_request.url_title, :page => 100
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises ActiveRecord::RecordNotFound if the request is embargoed' do
    badger_request.create_embargo(:publish_at => Time.now + 3.days)
    expect {
      get :similar, :url_title => badger_request.url_title
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

end

describe RequestController, "when caching fragments" do
  it "should not fail with long filenames" do
    long_name = "blahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblah.txt"
    info_request = double(InfoRequest, :prominence => 'normal',
                                       :is_public? => true,
                                       :embargo => nil)
    incoming_message = double(IncomingMessage, :info_request => info_request,
                            :parse_raw_email! => true,
                            :info_request_id => 132,
                            :id => 44,
                            :get_attachments_for_display => nil,
                            :apply_masks => nil,
                            :prominence => 'normal',
                            :is_public? => true)
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

      it "re-editing preserves the message body" do
        params = @default_post_params.merge(:preview => 0, :reedit => 1)
        post :new_batch, params, { :user_id => @user.id }
        expect(assigns[:outgoing_message].body).
          to include('This is a silly letter.')
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

describe RequestController, "when the site is in read_only mode" do
  before do
    allow(AlaveteliConfiguration).to receive(:read_only).and_return("Down for maintenance")
  end

  it "redirects to the frontpage_url" do
    get :new
    expect(response).to redirect_to frontpage_url
  end

  it "shows a flash message to alert the user" do
    get :new
    expected_message = '<p>Alaveteli is currently in maintenance. You ' \
                       'can only view existing requests. You cannot make ' \
                       'new ones, add followups or annotations, or ' \
                       'otherwise change the database.</p> '\
                       '<p>Down for maintenance</p>'
    expect(flash[:notice]).to eq expected_message
  end

  context "when annotations are disabled" do
    before do
      allow(controller).to receive(:feature_enabled?).with(:annotations).and_return(false)
    end

    it "doesn't mention annotations in the flash message" do
      get :new
      expected_message = '<p>Alaveteli is currently in maintenance. You ' \
                         'can only view existing requests. You cannot make ' \
                         'new ones, add followups or otherwise change the ' \
                         'database.</p> <p>Down for maintenance</p>'
      expect(flash[:notice]).to eq expected_message
    end
  end
end

describe RequestController do

  describe 'GET #details' do

    let(:info_request){ FactoryGirl.create(:info_request)}

    it 'renders the details template' do
      get :details, :url_title => info_request.url_title
      expect(response).to render_template('details')
    end

    it 'assigns the info_request' do
      get :details, :url_title => info_request.url_title
      expect(assigns[:info_request]).to eq(info_request)
    end

    it 'assigns columns' do
      get :details, :url_title => info_request.url_title
      expected_columns = ['id',
                          'event_type',
                          'created_at',
                          'described_state',
                          'last_described_at',
                          'calculated_state' ]
      expect(assigns[:columns]).to eq expected_columns
    end

    context 'when the request is hidden' do

      before do
        info_request.prominence = 'hidden'
        info_request.save!
      end

      it 'returns a 403' do
        get :details, :url_title => info_request.url_title
        expect(response.code).to eq("403")
      end

      it 'shows the hidden request template' do
        get :details, :url_title => info_request.url_title
        expect(response).to render_template("request/hidden")
      end

    end

    context 'when the request is embargoed' do

      before do
        info_request.create_embargo(:publish_at => Time.now + 3.days)
      end

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect{ get :details, :url_title => info_request.url_title }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end


  end

end

describe RequestController do
  describe 'GET #describe_state_message' do
    let(:info_request){ FactoryGirl.create(:info_request_with_incoming) }

    it 'assigns the info_request to the view' do
      get :describe_state_message, :url_title => info_request.url_title,
                                   :described_state => 'error_message'
      expect(assigns[:info_request]).to eq info_request
    end

    it 'assigns the described state to the view' do
      get :describe_state_message, :url_title => info_request.url_title,
                                   :described_state => 'error_message'
      expect(assigns[:described_state]).to eq 'error_message'
    end

    it 'assigns the last info request event id to the view' do
       get :describe_state_message, :url_title => info_request.url_title,
                                   :described_state => 'error_message'
      expect(assigns[:last_info_request_event_id])
        .to eq info_request.last_event_id_needing_description
    end

    it 'assigns the title to the view' do
      get :describe_state_message, :url_title => info_request.url_title,
                                   :described_state => 'error_message'
      expect(assigns[:title]).to eq "I've received an error message"
    end

    context 'when the request is embargoed' do
      let(:info_request){ FactoryGirl.create(:embargoed_request) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect{ get :describe_state_message,
                      :url_title => info_request.url_title,
                      :described_state => 'error_message' }
          .to raise_error(ActiveRecord::RecordNotFound)

      end

    end
  end
end

describe RequestController do

  describe 'GET #download_entire_request' do
    context 'when the request is embargoed' do
      let(:info_request){ FactoryGirl.create(:embargoed_request) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect{ get :download_entire_request,
                    :url_title => info_request.url_title }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

describe RequestController do

  describe 'GET #show_request_event' do

    context 'when the event is an incoming message' do
      let(:event){ FactoryGirl.create(:response_event) }

      it 'returns a 301 status' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response.status).to eq(301)
      end

      it 'redirects to the incoming message path' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response)
          .to redirect_to(incoming_message_path(event.incoming_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.now + 1.day)
        expect{ get :show_request_event, :info_request_event_id => event.id }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when the event is an outgoing message' do
      let(:event){ FactoryGirl.create(:sent_event) }

      it 'returns a 301 status' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response.status).to eq(301)
      end

      it 'redirects to the outgoing message path' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response)
          .to redirect_to(outgoing_message_path(event.outgoing_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.now + 1.day)
        expect{ get :show_request_event, :info_request_event_id => event.id }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'for any other kind of event' do
      let(:event){ FactoryGirl.create(:info_request_event) }

      it 'returns a 301 status' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response.status).to eq(301)
      end

      it 'redirects to the request path' do
        get :show_request_event, :info_request_event_id => event.id
        expect(response)
          .to redirect_to(show_request_path(event.info_request.url_title))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.now + 1.day)
        expect{ get :show_request_event, :info_request_event_id => event.id }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end

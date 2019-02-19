# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestController, "when listing recent requests" do
  before(:each) do
    load_raw_emails_data
    get_fixtures_xapian_index
  end

  it "should be successful" do
    get :list, params: { :view => 'all' }
    expect(response).to be_success
  end

  it "should render with 'list' template" do
    get :list, params: { :view => 'all' }
    expect(response).to render_template('list')
  end

  it "should return 404 for pages we don't want to serve up" do
    xap_results = double(ActsAsXapian::Search,
                       :results => (1..25).to_a.map { |m| { :model => m } },
                       :matches_estimated => 1000000)
    expect {
      get :list, params: { :view => 'all', :page => 100 }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "returns 404 for non html requests" do
    get :list, params: { :view => "all", :format => :json }
    expect(response.status).to eq(404)
  end

  it 'should not raise an error for a page param of less than zero, but should treat it as
        a param of 1' do
    expect {
      get :list, params: { :view => 'all', :page => "-1" }
    }.not_to raise_error
    expect(assigns[:page]).to eq(1)
  end

end

describe RequestController, "when showing one request" do
  render_views

  before(:each) do
    load_raw_emails_data
  end

  it "should be successful" do
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to be_success
  end

  it "should render with 'show' template" do
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to render_template('show')
  end

  it "should assign the request" do
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(assigns[:info_request]).to eq(info_requests(:fancy_dog_request))
  end

  it "should redirect from a numeric URL to pretty one" do
    get :show, params: { :url_title => info_requests(:naughty_chicken_request).id.to_s }
    expect(response).to redirect_to(:action => 'show', :url_title => info_requests(:naughty_chicken_request).url_title)
  end

  it 'should return a 404 for GET requests to a malformed request URL' do
    expect {
      get :show, params: { :url_title => '228%85' }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "redirecting pro users to the pro context" do
    let(:pro_user) { FactoryBot.create(:pro_user) }

    context "when showing pros their own requests" do
      context "when the request is embargoed" do
        let(:info_request) do
          FactoryBot.create(:embargoed_request, user: pro_user)
        end

        it "should always redirect to the pro version of the page" do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            get :show, params: { url_title: info_request.url_title }
            expect(response).to redirect_to show_alaveteli_pro_request_path(
              url_title: info_request.url_title)
          end
        end
      end

      context "when the request is not embargoed" do
        let(:info_request) do
          FactoryBot.create(:info_request, user: pro_user)
        end

        it "should not redirect to the pro version of the page" do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            get :show, params: { url_title: info_request.url_title }
            expect(response).to be_success
          end
        end
      end
    end

    context 'when a cancelled pro views their embargoed request' do

      before do
        pro_user.remove_role(:pro)
      end

      let(:info_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      it 'redirects to the pro version of the page' do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, params: { url_title: info_request.url_title }
          expect(response).to redirect_to show_alaveteli_pro_request_path(
            url_title: info_request.url_title)
        end
      end

      it 'uses the pro livery' do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, params: { url_title: info_request.url_title, pro: '1' }
          expect(assigns[:in_pro_area]).to be true
        end
      end
    end

    context "when showing pros a someone else's request" do
      it "should not redirect to the pro version of the page" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, params: { url_title: 'why_do_you_have_such_a_fancy_dog' }
          expect(response).to be_success
        end
      end
    end
  end

  context 'when the request is embargoed' do
    it 'raises ActiveRecord::RecordNotFound' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect {
        get :show, params: { :url_title => embargoed_request.url_title }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "doesn't even redirect from a numeric id" do
      embargoed_request = FactoryBot.create(:embargoed_request)
      expect {
        get :show, params: { :url_title => embargoed_request.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'when showing an external request' do
    describe 'when viewing anonymously' do
      it 'should be successful' do
        get :show, params: { :url_title => 'balalas' },
                   session: { :user_id => nil }
        expect(response).to be_success
      end
    end

    describe 'when the request is being viewed by an admin' do
      def make_request
        get :show, params: { :url_title => 'balalas' },
                   session: { :user_id => users(:admin_user).id }
      end

      it 'should be successful' do
        make_request
        expect(response).to be_success
      end
    end
  end

  describe 'when handling an update_status parameter' do

    describe 'when the request is external' do

      it 'should assign the "update status" flag to the view as falsey if the parameter is present' do
        get :show, params: { :url_title => 'balalas', :update_status => 1 }
        expect(assigns[:update_status]).to be_falsey
      end

      it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
        get :show, params: { :url_title => 'balalas' }
        expect(assigns[:update_status]).to be_falsey
      end

    end

    it 'should assign the "update status" flag to the view as truthy if the parameter is present' do
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   :update_status => 1
                 }
      expect(assigns[:update_status]).to be_truthy
    end

    it 'should assign the "update status" flag to the view as falsey if the parameter is not present' do
      get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
      expect(assigns[:update_status]).to be_falsey
    end

    it 'should require login' do
      session[:user_id] = nil
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   :update_status => 1
                 }
      expect(response).
        to redirect_to(signin_path(:token => get_last_post_redirect.token))
    end

    it 'should work if logged in as the requester' do
      session[:user_id] = users(:bob_smith_user).id
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   :update_status => 1
                 }
      expect(response).to render_template "request/show"
    end

    it 'should not work if logged in as not the requester' do
      session[:user_id] = users(:silly_name_user).id
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   :update_status => 1
                 }
      expect(response).to render_template "user/wrong_user"
    end

    it 'should work if logged in as an admin user' do
      session[:user_id] = users(:admin_user).id
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   :update_status => 1
                 }
      expect(response).to render_template "request/show"
    end
  end

  describe 'when params[:pro] is true and a pro user is logged in' do
    let(:pro_user) { FactoryBot.create(:pro_user) }

    before :each do
      session[:user_id] = pro_user.id
      get :show, params: {
                   :url_title => 'why_do_you_have_such_a_fancy_dog',
                   pro: "1"
                 }
    end

    it "should set @in_pro_area to true" do
      expect(assigns[:in_pro_area]).to be true
    end

    it "should set @sidebar_template to the pro sidebar" do
      expect(assigns[:sidebar_template]).
        to eq ("alaveteli_pro/info_requests/sidebar")
    end
  end

  describe 'when params[:pro] is not set' do
    before :each do
      get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    end

    it "should set @in_pro_area to false" do
      expect(assigns[:in_pro_area]).to be false
    end

    it "should set @sidebar_template to the normal sidebar" do
      expect(assigns[:sidebar_template]).to eq ("sidebar")
    end
  end

  describe "@show_top_describe_state_form" do
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:pro_request) { FactoryBot.create(:embargoed_request, user: pro_user) }

    context "when @in_pro_area is true" do
      it "is false" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, params: {
                       :url_title => pro_request.url_title,
                       :pro => "1",
                       :update_status => "1"
                     }
          expect(assigns[:show_top_describe_state_form]).to be false
        end
      end
    end

    context "when @in_pro_area is false" do
      context "and @update_status is false" do
        it "is false" do
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: { :url_title => info_request.url_title }
          expect(assigns[:show_top_describe_state_form]).to be false
        end

        context "but the request is awaiting_description" do
          it "is true" do
            get :show, params: {
                         :url_title => 'why_do_you_have_such_a_fancy_dog'
                       }
            expect(assigns[:show_top_describe_state_form]).to be true
          end
        end
      end

      context "and @update_status is true" do
        it "is true" do
          session[:user_id] = users(:bob_smith_user).id
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: {
                       :url_title => info_request.url_title,
                       :update_status => "1"
                     }
          expect(assigns[:show_top_describe_state_form]).to be true
        end

        context "and the request is awaiting_description" do
          it "is true" do
            get :show, params: {
                         :url_title => 'why_do_you_have_such_a_fancy_dog',
                         :update_status => "1"
                       }
            expect(assigns[:show_top_describe_state_form]).to be true
          end
        end
      end
    end

    context "when there are no valid state transitions" do
      it "is false" do
        info_request = FactoryBot.create(:info_request)
        info_request.set_described_state('not_foi')
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_top_describe_state_form]).to be false
      end
    end
  end

  describe "@show_bottom_describe_state_form" do
    let(:pro_user) { FactoryBot.create(:pro_user) }
    let(:pro_request) { FactoryBot.create(:embargoed_request, user: pro_user) }

    context "when @in_pro_area is true" do
      it "is false" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, params: {
                       :url_title => pro_request.url_title,
                       :pro => "1"
                     }
          expect(assigns[:show_bottom_describe_state_form]).to be false
        end
      end
    end

    context "when @in_pro_area is false" do
      context "and the request is awaiting_description" do
        it "is true" do
          get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
          expect(assigns[:show_bottom_describe_state_form]).to be true
        end
      end

      context "and the request is not awaiting_description" do
        it "is false" do
          info_request = info_requests(:naughty_chicken_request)
          expect(info_request.awaiting_description).to be false
          get :show, params: { :url_title => info_request.url_title }
          expect(assigns[:show_bottom_describe_state_form]).to be false
        end
      end
    end

    context "when there are no valid state transitions" do
      it "is false" do
        info_request = FactoryBot.create(:info_request)
        info_request.set_described_state('not_foi')
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_bottom_describe_state_form]).to be false
      end
    end
  end

  it "should set @state_transitions for the request" do
    info_request = FactoryBot.create(:info_request)
    expected_transitions = {
      :pending => {
        "waiting_response"      => "<strong>No response</strong> has been received <small>(maybe there's just an acknowledgement)</small>",
        "waiting_clarification" => "<strong>Clarification</strong> has been requested",
        "gone_postal"           => "A response will be sent <strong>by post</strong>"
      },
      :complete => {
        "not_held"              => "The authority do <strong>not have</strong> the information <small>(maybe they say who does)</small>",
        "partially_successful"  => "<strong>Some of the information</strong> has been sent ",
        "successful"            => "<strong>All the information</strong> has been sent",
        "rejected"              => "The request has been <strong>refused</strong>"
      },
      :other => {
        "error_message"         => "An <strong>error message</strong> has been received"
      }
    }
    get :show, params: { :url_title => info_request.url_title }
    expect(assigns(:state_transitions)).to eq(expected_transitions)
  end

  describe "showing update status actions" do
    let(:user) { FactoryBot.create(:user) }

    before do
      session[:user_id] = user.id
    end

    context "when the request is old and unclassified" do
      let(:info_request) { FactoryBot.create(:old_unclassified_request) }

      it "@show_owner_update_status_action should be false" do
        expect(info_request.is_old_unclassified?).to be true
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be false
      end

      it "@show_other_user_update_status_action should be true" do
        expect(info_request.is_old_unclassified?).to be true
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_other_user_update_status_action]).to be true
      end
    end

    context "when the request is not old and unclassified" do
      let(:info_request) { FactoryBot.create(:info_request) }

      it "@show_owner_update_status_action should be true" do
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be true
      end

      it "@show_other_user_update_status_action should be false" do
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_other_user_update_status_action]).to be false
      end
    end

    context "when there are no state_transitions" do
      let(:info_request) { FactoryBot.create(:info_request) }

      before do
        info_request.set_described_state('not_foi')
      end

      it "should hide all status update options" do
        get :show, params: { :url_title => info_request.url_title }
        expect(assigns[:show_owner_update_status_action]).to be false
        expect(assigns[:show_other_user_update_status_action]).to be false
      end
    end
  end
end

describe RequestController do
  describe 'GET get_attachment' do

    let(:info_request){ FactoryBot.create(:info_request_with_incoming_attachments) }

    def get_attachment(params = {})
      default_params = { :incoming_message_id =>
                           info_request.incoming_messages.first.id,
                         :id => info_request.id,
                         :part => 2,
                         :file_name => 'interesting.pdf' }
      get :get_attachment, params: default_params.merge(params)
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
      ugly_id = "#{FactoryBot.create(:info_request).id}95"
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
      info_request = FactoryBot.create(:info_request_with_html_attachment)
      get :get_attachment,
           params: {
             :incoming_message_id => info_request.incoming_messages.first.id,
             :id => info_request.id,
             :part => 5,
             :file_name => 'interesting.html',
             :skip_cache => 1
           }
      expect(response.body).to match('dull')
    end

    it "should not download attachments with wrong file name" do
      info_request = FactoryBot.create(:info_request_with_html_attachment)
      get :get_attachment,
           params: {
             :incoming_message_id => info_request.incoming_messages.first.id,
             :id => info_request.id,
             :part => 2,
             :file_name => 'http://trying.to.hack',
             :skip_cache => 1
           }
      expect(response.status).to eq(303)
    end

    it "should sanitise HTML attachments" do
      info_request = FactoryBot.create(:info_request_with_html_attachment)
      get :get_attachment,
          params: {
            :incoming_message_id => info_request.incoming_messages.first.id,
            :id => info_request.id,
            :part => 2,
            :file_name => 'interesting.html',
            :skip_cache => 1
          }

      # Nokogiri adds the meta tag; see
      # https://github.com/sparklemotion/nokogiri/issues/1008
      expected = <<-EOF.squish
      <!DOCTYPE html>
      <html>
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        </head>
        <body>dull
        </body>
      </html>
      EOF

      expect(response.body.squish).to eq(expected)
    end

    it "censors attachments downloaded directly" do
      info_request = FactoryBot.create(:info_request_with_html_attachment)
      info_request.censor_rules.create!(:text => 'dull',
                                       :replacement => "Mouse",
                                       :last_edit_editor => 'unknown',
                                       :last_edit_comment => 'none')
      get :get_attachment,
          params: {
            :incoming_message_id => info_request.incoming_messages.first.id,
            :id => info_request.id,
            :part => 2,
            :file_name => 'interesting.html',
            :skip_cache => 1
          }
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Mouse"
    end

    it "should censor with rules on the user (rather than the request)" do
      info_request = FactoryBot.create(:info_request_with_html_attachment)
      info_request.user.censor_rules.create!(:text => 'dull',
                                       :replacement => "Mouse",
                                       :last_edit_editor => 'unknown',
                                       :last_edit_comment => 'none')
      get :get_attachment,
          params: {
            :incoming_message_id => info_request.incoming_messages.first.id,
            :id => info_request.id,
            :part => 2,
            :file_name => 'interesting.html',
            :skip_cache => 1
          }
      expect(response.content_type).to eq("text/html")
      expect(response.body).to have_content "Mouse"
    end

    it 'returns an ActiveRecord::RecordNotFound error for an embargoed request' do
      info_request = FactoryBot.create(:embargoed_request)
      expect {
        get :get_attachment,
            params: {
              :incoming_message_id => info_request.incoming_messages.first.id,
              :id => info_request.id,
              :part => 2,
              :file_name => 'interesting.pdf',
              :skip_cache => 1
            }
      }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end

describe RequestController do
  describe 'GET get_attachment_as_html' do
    let(:info_request){ FactoryBot.create(:info_request_with_incoming_attachments) }

    def get_html_attachment(params = {})
      default_params = { :incoming_message_id =>
                           info_request.incoming_messages.first.id,
                         :id => info_request.id,
                         :part => 2,
                         :file_name => 'interesting.pdf.html' }
      get :get_attachment_as_html, params: default_params.merge(params)
    end

    it "should return 404 for ugly URLs containing a request id that isn't an integer" do
      ugly_id = "55195"
      expect { get_html_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should return 404 for ugly URLs contain a request id that isn't an
        integer, even if the integer prefix refers to an actual request" do
      ugly_id = "#{FactoryBot.create(:info_request).id}95"
      expect { get_html_attachment(:id => ugly_id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns an ActiveRecord::RecordNotFound error for an embargoed request' do
      info_request = FactoryBot.create(:embargoed_request)
      expect {
        get :get_attachment_as_html,
            params: {
              :incoming_message_id => info_request.incoming_messages.first.id,
              :id => info_request.id,
              :part => 2,
              :file_name => 'interesting.pdf.html'
            }
      }.to raise_error ActiveRecord::RecordNotFound
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
      @info_request = FactoryBot.create(:info_request_with_incoming_attachments,
                                        :prominence => 'hidden')
    end

    it "should not show request if you're not logged in" do
      get :show, params: { :url_title => @info_request.url_title }
      expect_hidden('hidden')
    end

    it "should not show request even if logged in as their owner" do
      session[:user_id] = @info_request.user.id
      get :show, params: { :url_title => @info_request.url_title }
      expect_hidden('hidden')
    end

    it 'should not show request if requested using json' do
      session[:user_id] = @info_request.user.id
      get :show, params: {
                   :url_title => @info_request.url_title,
                   :format => 'json'
                 }
      expect(response.code).to eq('403')
    end

    it "should show request if logged in as super user" do
      session[:user_id] = FactoryBot.create(:admin_user).id
      get :show, params: { :url_title => @info_request.url_title }
      expect(response).to render_template('show')
    end

    it "should not download attachments" do
      incoming_message = @info_request.incoming_messages.first
      get :get_attachment,
          params: {
            :incoming_message_id => incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect_hidden('request/hidden')
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      incoming_message = @info_request.incoming_messages.first
      expect do
        get :get_attachment_as_html,
            params: {
              :incoming_message_id => incoming_message.id,
              :id => @info_request.id,
              :part => 2,
              :file_name => 'interesting.pdf'
            }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  context 'when the request is requester_only' do

    before(:each) do
      @info_request = FactoryBot.create(:info_request_with_incoming_attachments,
                                        :prominence => 'requester_only')
    end

    it "should not show request if you're not logged in" do
      get :show, params: { :url_title => @info_request.url_title }
      expect_hidden('hidden')
    end

    it "should not show request if logged in but not the requester" do
      session[:user_id] = FactoryBot.create(:user).id
      get :show, params: { :url_title => @info_request.url_title }
      expect_hidden('hidden')
    end

    it "should show request to requester" do
      session[:user_id] = @info_request.user.id
      get :show, params: { :url_title => @info_request.url_title }
      expect(response).to render_template('show')
    end

    it "shouild show request to admin" do
      session[:user_id] = FactoryBot.create(:admin_user).id
      get :show, params: { :url_title => @info_request.url_title }
      expect(response).to render_template('show')
    end

    it 'should not cache an attachment when showing an attachment to the requester' do
      session[:user_id] = @info_request.user.id
      incoming_message = @info_request.incoming_messages.first
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment,
          params: {
            :incoming_message_id => incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf'
          }
    end

    it 'should not cache an attachment when showing an attachment to the admin' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      incoming_message = @info_request.incoming_messages.first
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment,
          params: {
            :incoming_message_id => incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf'
          }
    end
  end

  context 'when the incoming message has prominence hidden' do

    before(:each) do
      @incoming_message = FactoryBot.create(:incoming_message_with_attachments,
                                            :prominence => 'hidden')
      @info_request = @incoming_message.info_request
    end

    it "should not download attachments for a non-logged in user" do
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect_hidden('request/hidden_correspondence')
    end

    it 'should not download attachments for the request owner' do
      session[:user_id] = @info_request.user.id
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect_hidden('request/hidden_correspondence')
    end

    it 'should download attachments for an admin user' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      expect do
        get :get_attachment_as_html,
            params: {
              :incoming_message_id => @incoming_message.id,
              :id => @info_request.id,
              :part => 2,
              :file_name => 'interesting.pdf',
              :skip_cache => 1
            }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should not cache an attachment when showing an attachment to the requester or admin' do
      session[:user_id] = @info_request.user.id
      expect(@controller).not_to receive(:foi_fragment_cache_write)
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf'
          }
    end

  end

  context 'when the incoming message has prominence requester_only' do

    before(:each) do
      @incoming_message = FactoryBot.create(:incoming_message_with_attachments,
                                            :prominence => 'requester_only')
      @info_request = @incoming_message.info_request
    end

    it "should not download attachments for a non-logged in user" do
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect_hidden('request/hidden_correspondence')
    end

    it 'should download attachments for the request owner' do
      session[:user_id] = @info_request.user.id
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should download attachments for an admin user' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      get :get_attachment,
          params: {
            :incoming_message_id => @incoming_message.id,
            :id => @info_request.id,
            :part => 2,
            :file_name => 'interesting.pdf',
            :skip_cache => 1
          }
      expect(response.content_type).to eq('application/pdf')
      expect(response).to be_success
    end

    it 'should not generate an HTML version of an attachment for a request whose prominence
            is hidden even for an admin but should return a 404' do
      session[:user_id] = FactoryBot.create(:admin_user).id
      expect do
        get :get_attachment_as_html,
            params: {
              :incoming_message_id => @incoming_message.id,
              :id => @info_request.id,
              :part => 2,
              :file_name => 'interesting.pdf',
              :skip_cache => 1
            }
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

  it "should return matching bodies" do
    session[:user_id] = @user.id
    get :select_authority, params: { :query => "Quango" }

    expect(response).to render_template('select_authority')
    assigns[:xapian_requests].results.size == 1
    expect(assigns[:xapian_requests].results[0][:model].name).to eq(public_bodies(:geraldine_public_body).name)
  end

  it "remembers the search params" do
    session[:user_id] = @user.id
    search_params = {
      'query'  => 'Quango',
      'page'   => '1',
      'bodies' => '1'
    }

    get :select_authority, params: search_params

    flash_params =
      if rails5?
        flash[:search_params].to_unsafe_h
      else
        flash[:search_params]
      end
    expect(flash_params).to eq(search_params)
  end

  describe 'when params[:pro] is true' do
    context "and a pro user is logged in " do
      let(:pro_user) { FactoryBot.create(:pro_user) }

      before do
        session[:user_id] = pro_user.id
      end

      it "should set @in_pro_area to true" do
        get :select_authority, params: { pro: "1" }
        expect(assigns[:in_pro_area]).to be true
      end

      it "should not redirect pros to the info request form for pros" do
        with_feature_enabled(:alaveteli_pro) do
          public_body = FactoryBot.create(:public_body)
          get :select_authority, params: { pro: "1" }
          expect(response).to be_success
        end
      end
    end

    context "and a pro user is not logged in" do
      before do
        session[:user_id] = nil
      end

      it "should set @in_pro_area to false" do
        get :select_authority, params: { pro: "1" }
        expect(assigns[:in_pro_area]).to be false
      end

      it "should not redirect users to the info request form for pros" do
        with_feature_enabled(:alaveteli_pro) do
          public_body = FactoryBot.create(:public_body)
          get :select_authority, params: { pro: "1" }
          expect(response).to be_success
        end
      end
    end
  end

  describe 'when params[:pro] is not set' do
    it "should set @in_pro_area to false" do
      get :select_authority
      expect(assigns[:in_pro_area]).to be false
    end

    it "should redirect pros to the info request form for pros" do
      with_feature_enabled(:alaveteli_pro) do
        pro_user = FactoryBot.create(:pro_user)
        public_body = FactoryBot.create(:public_body)
        session[:user_id] = pro_user.id
        get :select_authority
        expect(response).to redirect_to(new_alaveteli_pro_info_request_url)
      end
    end
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
    get :new, params: { :public_body_id => @body.id }
    expect(response).to render_template('new_bad_contact')
  end

  context "the outgoing message includes an email address" do

    context "there is no logged in user" do

      it "displays a flash error message without escaping the HTML" do
        post :new, params: {
                     :info_request => {
                       :public_body_id => @body.id,
                       :title => "Test Request"
                     },
                     :outgoing_message => { :body => "me@here.com" },
                     :submitted_new_request => 1,
                     :preview => 1
                   }

        expect(response.body).to have_css('div#error p')
        expect(response.body).to_not have_content('<p>')
        expect(response.body).
          to have_content('You do not need to include your email')
      end

    end

    context "the user is logged in" do

      it "displays a flash error message without escaping the HTML" do
        session[:user_id] = @user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => @body.id,
                       :title => "Test Request" },
                     :outgoing_message => { :body => "me@here.com" },
                     :submitted_new_request => 1,
                     :preview => 1
                   }

        expect(response.body).to have_css('div#error p')
        expect(response.body).to_not have_content('<p>')
        expect(response.body).
          to have_content('You do not need to include your email')
      end

    end

  end

  context "the outgoing message includes a postcode" do

    it 'displays an error message warning about the postcode' do
      post :new, params: {
                   :info_request => {
                     :public_body_id => @body.id,
                     :title => "Test Request"
                   },
                   :outgoing_message => { :body => "SW1A 1AA" },
                   :submitted_new_request => 1,
                   :preview => 1
                 }

      expect(response.body).to have_content('Your request contains a postcode')
    end

  end

  it "should redirect pros to the pro version" do
    with_feature_enabled(:alaveteli_pro) do
      pro_user = FactoryBot.create(:pro_user)
      public_body = FactoryBot.create(:public_body)
      session[:user_id] = pro_user.id
      get :new, params: { :url_name => public_body.url_name }
      expected_url = new_alaveteli_pro_info_request_url(
        public_body: public_body.url_name)
      expect(response).to redirect_to(expected_url)
    end
  end

  it "should accept a public body parameter" do
    get :new, params: { :public_body_id => @body.id }
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
  end

  it 'assigns a default text for the request' do
    get :new, params: { :public_body_id => @body.id }
    expect(assigns[:info_request].public_body).to eq(@body)
    expect(response).to render_template('new')
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
  end

  it 'allows the default text to be set via the default_letter param' do
    get :new, params: { :url_name => @body.url_name, :default_letter => "test" }
    default_message = <<-EOF.strip_heredoc
    Dear Geraldine Quango,

    test

    Yours faithfully,
    EOF
    expect(assigns[:outgoing_message].body).to include(default_message.strip)
  end

  it 'should display one meaningful error message when no message body is added' do
    post :new, params: {
                 :info_request => { :public_body_id => @body.id },
                 :outgoing_message => { :body => "" },
                 :submitted_new_request => 1,
                 :preview => 1
               }
    expect(assigns[:info_request].errors.full_messages).not_to include('Outgoing messages is invalid')
    expect(assigns[:outgoing_message].errors.full_messages).to include('Body Please enter your letter requesting information')
  end

  it "should give an error and render 'new' template when a summary isn't given" do
    post :new,
         params: {
           :info_request => { :public_body_id => @body.id },
           :outgoing_message => {
             :body =>
               "This is a silly letter. It is too short to be interesting."
           },
           :submitted_new_request => 1,
           :preview => 1
         }
    expect(assigns[:info_request].errors[:title]).not_to be_nil
    expect(response).to render_template('new')
  end

  it "should redirect to sign in page when input is good and nobody is logged in" do
    params = { :info_request => { :public_body_id => @body.id,
                                  :title => "Why is your quango called Geraldine?", :tag_string => "" },
               :outgoing_message => { :body => "This is a silly letter. It is too short to be interesting." },
               :submitted_new_request => 1, :preview => 0
               }
    post :new, params: params
    expect(response).
      to redirect_to(signin_path(:token => get_last_post_redirect.token))
    # post_redirect.post_params.should == params # TODO: get this working. there's a : vs '' problem amongst others
  end

  it 'redirects to the frontpage if the action is sent the invalid
        public_body param' do
    post :new, params: {
                 :info_request => {
                   :public_body => @body.id,
                   :title => 'Why Geraldine?',
                   :tag_string => ''
                 },
                 :outgoing_message => { :body => 'This is a silly letter.'},
                 :submitted_new_request => 1,
                 :preview => 1
               }
    expect(response).to redirect_to frontpage_url
  end

  it "should show preview when input is good" do
    session[:user_id] = @user.id
    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "Why is your quango called Geraldine?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                  :body => "This is a silly letter. It is too short to be interesting."
                 },
                 :submitted_new_request => 1,
                 :preview => 1
               }
    expect(response).to render_template('preview')
  end

  it "should allow re-editing of a request" do
    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "Why is your quango called Geraldine?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "This is a silly letter. It is too short to be interesting."
                 },
                 :submitted_new_request => 1,
                 :preview => 0,
                 :reedit => "Re-edit this request"
               }
    expect(response).to render_template('new')
  end

  it "re-editing preserves the message body" do
    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "Why is your quango called Geraldine?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "This is a silly letter. It is too short to be interesting."
                 },
                 :submitted_new_request => 1,
                 :preview => 0,
                 :reedit => "Re-edit this request"
               }
    expect(assigns[:outgoing_message].body).
      to include('This is a silly letter. It is too short to be interesting.')
  end

  it "should create the request and outgoing message, and send the outgoing message by email, and redirect to request page when input is good and somebody is logged in" do
    session[:user_id] = @user.id
    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "Why is your quango called Geraldine?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "This is a silly letter. It is too short to be interesting."
                 },
                 :submitted_new_request => 1,
                 :preview => 0
               }

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
    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "Why is your quango called Geraldine?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "This is a silly letter. It is too short to be interesting."
                 },
                 :submitted_new_request => 1,
                 :preview => 0
               }

    expect(flash[:request_sent]).to be true
  end

  it "should give an error if the same request is submitted twice" do
    session[:user_id] = @user.id

    # We use raw_body here, so white space is the same
    post :new,
         params: {
           :info_request => {
             :public_body_id => info_requests(:fancy_dog_request).public_body_id,
             :title => info_requests(:fancy_dog_request).title
           },
           :outgoing_message => {
             :body => info_requests(:fancy_dog_request).outgoing_messages[0].raw_body
           },
           :submitted_new_request => 1,
           :preview => 0,
           :mouse_house => 1
         }
    expect(response).to render_template('new')
  end

  it "should let you submit another request with the same title" do
    session[:user_id] = @user.id

    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "Why is your quango called Geraldine?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body =>
               "This is a silly letter. It is too short to be interesting."
           },
           :submitted_new_request => 1,
           :preview => 0
         }

    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "Why is your quango called Geraldine?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body => "This is a sensible letter. It is too long to be boring."
           },
           :submitted_new_request => 1,
           :preview => 0
         }

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
    session[:user_id] = users(:robin_user).id

    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "What is the answer to the ultimate question?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "Please supply the answer from your files."
                 },
                 :submitted_new_request => 1,
                 :preview => 0
               }
    expect(response).to redirect_to show_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "Why did the chicken cross the road?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body => "Please send me all the relevant documents you hold."
           },
           :submitted_new_request => 1,
           :preview => 0
         }
    expect(response).to redirect_to show_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "What's black and white and red all over?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body => "Please send all minutes of meetings and email records " \
                      "that address this question."
           },
           :submitted_new_request => 1,
           :preview => 0
         }
    expect(response).to render_template('user/rate_limited')
  end

  it 'should ignore the rate limit for specified users' do
    # Try to create three requests in succession.
    # (The limit set in config/test.yml is two.)
    session[:user_id] = users(:robin_user).id
    users(:robin_user).no_limit = true
    users(:robin_user).save!

    post :new, params: {
                 :info_request => {
                   :public_body_id => @body.id,
                   :title => "What is the answer to the ultimate question?",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "Please supply the answer from your files."
                 },
                 :submitted_new_request => 1,
                 :preview => 0
               }
    expect(response).to redirect_to show_request_url(:url_title => 'what_is_the_answer_to_the_ultima')


    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "Why did the chicken cross the road?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body => "Please send me all the relevant documents you hold."
           },
           :submitted_new_request => 1,
           :preview => 0
         }
    expect(response).to redirect_to show_request_url(:url_title => 'why_did_the_chicken_cross_the_ro')

    post :new,
         params: {
           :info_request => {
             :public_body_id => @body.id,
             :title => "What's black and white and red all over?",
             :tag_string => ""
           },
           :outgoing_message => {
             :body => "Please send all minutes of meetings and email records " \
                      "that address this question."
           },
           :submitted_new_request => 1,
           :preview => 0
         }
    expect(response).to redirect_to show_request_url(:url_title => 'whats_black_and_white_and_red_al')
  end

  describe 'when rendering a reCAPTCHA' do

    context 'when new_request_recaptcha disabled' do

      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(false)
      end

      it 'sets render_recaptcha to false' do
        post :new, params: {
                     :info_request => {
                       :public_body_id => @body.id,
                       :title => "What's black and white and red all over?",
                       :tag_string => ""
                     },
                     :outgoing_message => { :body => "Please send info" },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(assigns[:render_recaptcha]).to eq(false)
      end
    end

    context 'when new_request_recaptcha is enabled' do

      before do
        allow(AlaveteliConfiguration).to receive(:new_request_recaptcha)
          .and_return(true)
      end

      it 'sets render_recaptcha to true if there is no logged in user' do
        post :new, params: {
                     :info_request => {
                       :public_body_id => @body.id,
                       :title => "What's black and white and red all over?",
                       :tag_string => ""
                     },
                     :outgoing_message => { :body => "Please send info" },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to true if there is a logged in user who is not
            confirmed as not spam' do
        session[:user_id] =
          FactoryBot.create(:user, :confirmed_not_spam => false).id
        post :new, params: {
                     :info_request => {
                       :public_body_id => @body.id,
                       :title => "What's black and white and red all over?",
                       :tag_string => ""
                     },
                     :outgoing_message => { :body => "Please send info" },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(assigns[:render_recaptcha]).to eq(true)
      end

      it 'sets render_recaptcha to false if there is a logged in user who is
            confirmed as not spam' do
        session[:user_id] = FactoryBot.create(:user,
                                              :confirmed_not_spam => true).id
        post :new, params: {
                     :info_request => {
                        :public_body_id => @body.id,
                        :title => "What's black and white and red all over?",
                        :tag_string => ""
                      },
                      :outgoing_message => { :body => "Please send info" },
                      :submitted_new_request => 1,
                      :preview => 0
                    }
        expect(assigns[:render_recaptcha]).to eq(false)
      end

      context 'when the reCAPTCHA information is not correct' do

        before do
          allow(controller).to receive(:verify_recaptcha).and_return(false)
        end

        let(:user) { FactoryBot.create(:user,
                                      :confirmed_not_spam => false) }
        let(:body) { FactoryBot.create(:public_body) }

        it 'shows an error message' do
          session[:user_id] = user.id
          post :new, params: {
                       :info_request => {
                         :public_body_id => body.id,
                         :title => "Some request text",
                         :tag_string => ""
                        },
                        :outgoing_message => {
                          :body => "Please supply the answer from your files."
                        },
                        :submitted_new_request => 1,
                        :preview => 0
                     }
          expect(flash[:error])
            .to eq('There was an error with the reCAPTCHA. Please try again.')
        end

        it 'renders the compose interface' do
          session[:user_id] = user.id
          post :new, params: {
                       :info_request => {
                         :public_body_id => body.id,
                         :title => "Some request text",
                         :tag_string => ""
                       },
                       :outgoing_message => {
                         :body => "Please supply the answer from your files."
                       },
                       :submitted_new_request => 1,
                       :preview => 0
                     }
          expect(response).to render_template("new")
        end

        it 'allows the request if the user is confirmed not spam' do
          user.confirmed_not_spam = true
          user.save!
          session[:user_id] = user.id
          post :new, params: {
                       :info_request => {
                         :public_body_id => body.id,
                         :title => "Some request text",
                         :tag_string => ""
                       },
                       :outgoing_message => {
                         :body => "Please supply the answer from your files."
                       },
                       :submitted_new_request => 1,
                       :preview => 0
                     }
          expect(response)
            .to redirect_to show_request_path(:url_title => 'some_request_text')
        end

      end

    end

  end

  context 'when the request subject line looks like spam' do

    let(:user) { FactoryBot.create(:user,
                                   :confirmed_not_spam => false) }
    let(:body) { FactoryBot.create(:public_body) }


    context 'when given a string containing unicode characters' do

      it 'converts the string to ASCII' do
        allow(AlaveteliConfiguration).to receive(:block_spam_requests).
          and_return(true)
        session[:user_id] = user.id
        title = "▩█ -Free Ɓrazzers Password Hăck Premium Account List 2017 ᒬᒬ"
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => title,
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

    end

    context 'when enable_anti_spam is false and block_spam_requests is true' do
      # double check that block_spam_subject? is behaving as expected
      before do
        allow(AlaveteliConfiguration).to receive(:enable_anti_spam).
          and_return(false)
        allow(AlaveteliConfiguration).to receive(:block_spam_requests).
          and_return(true)
      end

      it 'sends an exception notification' do
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

    end

    context 'when block_spam_subject? is true' do

      before do
        allow(@controller).to receive(:block_spam_subject?).and_return(true)
      end

      it 'sends an exception notification' do
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer from your files."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

      it 'shows an error message' do
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer from your files."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        expect(flash[:error])
          .to eq("Sorry, we're currently unable to send your request. Please try again later.")
      end

      it 'renders the compose interface' do
        session[:user_id] = user.id
        post :new,
               params: {
                 :info_request => {
                   :public_body_id => body.id,
                   :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                   :tag_string => ""
                 },
                 :outgoing_message => {
                   :body => "Please supply the answer from your files."
                 },
                 :submitted_new_request => 1,
                 :preview => 0
               }
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer from your files."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        expect(response)
          .to redirect_to show_request_path(:url_title => 'hd_watch_jason_bourne_online_fre')
      end

    end

    context 'when block_spam_subject? is false' do

      before do
        allow(@controller).to receive(:block_spam_subject?).and_return(false)
      end

      it 'sends an exception notification' do
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer from your files."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Spam request from user #{ user.id }/)
      end

      it 'allows the request' do
        session[:user_id] = user.id
        post :new,
             params: {
               :info_request => {
                 :public_body_id => body.id,
                 :title => "[HD] Watch Jason Bourne Online free MOVIE Full-HD",
                 :tag_string => ""
               },
               :outgoing_message => {
                 :body => "Please supply the answer from your files."
               },
               :submitted_new_request => 1,
               :preview => 0
             }
        expect(response)
          .to redirect_to show_request_path(:url_title => 'hd_watch_jason_bourne_online_fre')
      end

    end

  end

  describe 'when the request is from an IP address in a blocked country' do

    let(:user) { FactoryBot.create(:user,
                                   :confirmed_not_spam => false) }
    let(:body) { FactoryBot.create(:public_body) }

    before do
      allow(AlaveteliConfiguration).to receive(:restricted_countries).and_return('PH')
      allow(controller).to receive(:country_from_ip).and_return('PH')
    end

    context 'when block_restricted_country_ips? is true' do

      before do
        allow(@controller).
          to receive(:block_restricted_country_ips?).and_return(true)
      end

      it 'sends an exception notification' do
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/\(ip_in_blocklist\) from #{ user.id }/)
      end

      it 'shows an error message' do
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(flash[:error])
          .to eq("Sorry, we're currently unable to send your request. Please try again later.")
      end

      it 'renders the compose interface' do
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(response).to render_template("new")
      end

      it 'allows the request if the user is confirmed not spam' do
        user.confirmed_not_spam = true
        user.save!
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        expect(response)
          .to redirect_to show_request_path(:url_title => 'some_request_content')
      end

    end

    context 'when block_restricted_country_ips? is false' do

      before do
        allow(@controller).
          to receive(:block_restricted_country_ips?).and_return(false)
      end

      it 'sends an exception notification' do
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/\(ip_in_blocklist\) from #{ user.id }/)
      end

      it 'allows the request' do
        session[:user_id] = user.id
        post :new, params: {
                     :info_request => {
                       :public_body_id => body.id,
                       :title => "Some request content",
                       :tag_string => ""
                     },
                     :outgoing_message => {
                       :body => "Please supply the answer from your files."
                     },
                     :submitted_new_request => 1,
                     :preview => 0
                   }
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
    @body = FactoryBot.create(:public_body, :name => 'Test Quango')
  end

  it "should allow you to have one undescribed request" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1 ])
    session[:user_id] = @user.id
    get :new, params: { :public_body_id => @body.id }
    expect(response).to render_template('new')
  end

  it "should fail if more than one request undescribed" do
    allow(@user).to receive(:get_undescribed_requests).and_return([ 1, 2 ])
    session[:user_id] = @user.id
    get :new, params: { :public_body_id => @body.id }
    expect(response).to render_template('new_please_describe')
  end

  it "should fail if user is banned" do
    allow(@user).to receive(:can_file_requests?).and_return(false)
    allow(@user).to receive(:exceeded_limit?).and_return(false)
    expect(@user).to receive(:can_fail_html).and_return('FAIL!')
    session[:user_id] = @user.id
    get :new, params: { :public_body_id => @body.id }
    expect(response).to render_template('user/banned')
  end

end

describe RequestController do
  describe "POST describe_state" do
    describe 'if the request is external' do

      let(:external_request){ FactoryBot.create(:external_request) }

      it 'should redirect to the request page' do
        patch :describe_state, params: { :id => external_request.id }
        expect(response)
          .to redirect_to(show_request_path(external_request.url_title))
      end

    end

    describe 'when the request is internal' do

      let(:info_request){ FactoryBot.create(:info_request) }

      def post_status(status, info_request)
        patch :describe_state,
              params: {
                :incoming_message => {
                  :described_state => status
                },
                :id => info_request.id,
                :last_info_request_event_id =>
                  info_request.last_event_id_needing_description
              }
      end

      context 'when the request is embargoed' do

        let(:info_request){ FactoryBot.create(:embargoed_request) }

        it 'should raise ActiveRecord::NotFound' do
          expect{ post_status('rejected', info_request) }
            .to raise_error ActiveRecord::RecordNotFound
        end
      end

      it "should require login" do
        post_status('rejected', info_request)
        expect(response).
          to redirect_to(signin_path(:token => get_last_post_redirect.token))
      end

      it "should not classify the request if logged in as the wrong user" do
        session[:user_id] = FactoryBot.create(:user).id
        post_status('rejected', info_request)
        expect(response).to render_template('user/wrong_user')
      end

      describe 'when the request is old and unclassified' do

        let(:info_request){ FactoryBot.create(:old_unclassified_request)}

        describe 'when the user is not logged in' do

          it 'should require login' do
            session[:user_id] = nil
            post_status('rejected', info_request)
            expect(response)
              .to redirect_to(signin_path(:token => get_last_post_redirect.token))
          end

        end

        describe 'when the user is logged in as a different user' do

          let(:other_user){ FactoryBot.create(:user) }

          before do
            session[:user_id] = other_user.id
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
              expect(response).to redirect_to categorise_play_url
            end

            it 'shows a message thanking the user for a good deed' do
              post_status('rejected', info_request)
              expect(flash[:notice][:partial]).
                to eq("request_game/thank_you.html.erb")
              expect(flash[:notice][:locals]).
                to include(:info_request_title => info_request.title)
            end
          end

          context 'when the new status is "requires_admin"' do
            it "should send a mail to admins saying that the response requires admin
               and one to the requester noting the status change" do
              patch :describe_state,
                    params: {
                      :incoming_message => {
                        :described_state => "requires_admin",
                        :message => "a message"
                      },
                      :id => info_request.id,
                      :incoming_message_id => info_request.incoming_messages.last,
                      :last_info_request_event_id =>
                        info_request.last_event_id_needing_description
                    }

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
                patch :describe_state,
                      params: {
                        :incoming_message => {
                          :described_state => "requires_admin"
                        },
                        :id => info_request.id,
                        :incoming_message_id =>
                          info_request.incoming_messages.last,
                        :last_info_request_event_id =>
                          info_request.last_event_id_needing_description
                      }
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

        let(:admin_user){ FactoryBot.create(:admin_user) }
        let(:info_request){ FactoryBot.create(:info_request) }

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
          allow(mail_mock).to receive :deliver_now
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

        let(:admin_user){ FactoryBot.create(:admin_user) }
        let(:info_request){ FactoryBot.create(:info_request, :user => admin_user) }

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
          post_status('rejected', info_request)
          expect(flash[:notice][:partial]).
            to eq('request/describe_notices/rejected')
        end

        it 'should redirect to the unhappy page' do
          post_status('rejected', info_request)
          expect(response)
            .to redirect_to(help_unhappy_path(info_request.url_title))
        end

      end

      describe 'when logged in as the requestor' do

        let(:info_request) do
          FactoryBot.create(:info_request, :awaiting_description => true)
        end

        before do
          session[:user_id] = info_request.user_id
        end

        it "should let you know when you forget to select a status" do
          patch :describe_state,
                params: {
                  :id => info_request.id,
                  :last_info_request_event_id =>
                    info_request.last_event_id_needing_description
                }
          expect(response).to redirect_to show_request_url(:url_title => info_request.url_title)
          expect(flash[:error])
            .to eq("Please choose whether or not you got some of the information that you wanted.")
        end

        it "should not change the status if the request has changed while viewing it" do
          patch :describe_state,
                params: {
                  :incoming_message => { :described_state => "rejected" },
                  :id => info_request.id,
                  :last_info_request_event_id => 1
                }
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
          patch :describe_state,
                params: {
                  :incoming_message => { :described_state => "requires_admin" },
                  :id => info_request.id,
                  :incoming_message_id => info_request.incoming_messages.last,
                  :last_info_request_event_id =>
                    info_request.last_event_id_needing_description
                }
          expect(response)
            .to redirect_to describe_state_message_url(:url_title => info_request.url_title,
                                                       :described_state => "requires_admin")

          info_request.reload
          expect(info_request.described_state).not_to eq('requires_admin')
          expect(ActionMailer::Base.deliveries).to be_empty
        end

        context "message is included when classifying as requires_admin" do
          it "should send an email including the message" do
            patch :describe_state,
                  params: {
                    :incoming_message => {
                      :described_state => "requires_admin",
                      :message => "Something weird happened"
                    },
                    :id => info_request.id,
                    :last_info_request_event_id =>
                      info_request.last_event_id_needing_description
                  }

            deliveries = ActionMailer::Base.deliveries
            expect(deliveries.size).to eq(1)
            mail = deliveries[0]
            expect(mail.body).to match(/as needing admin/)
            expect(mail.body).to match(/Something weird happened/)
          end
        end

        it 'should show advice for the new state' do
          post_status('rejected', info_request)
          expect(flash[:notice][:partial]).
            to eq('request/describe_notices/rejected')
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

        let(:info_request){ FactoryBot.create(:info_request) }

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
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/waiting_response')
          end

          it 'should redirect to the "request url" with a message in the right tense when
              the response is overdue' do
            # Create the request with today's date
            info_request
            time_travel_to(info_request.date_response_required_by + 2.days) do
              expect_redirect('waiting_response',
                              show_request_path(info_request.url_title))
              expect(flash[:notice][:partial]).
                to eq('request/describe_notices/waiting_response_overdue')
            end
          end

          it 'should redirect to the "request url" with a message in the right tense when
              response is very overdue' do
            # Create the request with today's date
            info_request
            time_travel_to(info_request.date_very_overdue_after + 2.days) do
              expect_redirect('waiting_response',
                              help_unhappy_path(info_request.url_title))
              expect(flash[:notice][:partial]).
                to eq('request/describe_notices/waiting_response_very_overdue')
            end
          end
        end

        context 'when status is updated to "not held"' do

          it 'should redirect to the "request url"' do
            expect_redirect('not_held',
                            show_request_path(info_request.url_title))
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/not_held')
          end

        end

        context 'when status is updated to "successful"' do

          it 'should redirect to the "request url"' do
            expect_redirect('successful',
                            show_request_path(info_request.url_title))
          end

          it 'should show a message' do
            post_status('successful', info_request)
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/successful')
          end

        end

        context 'when status is updated to "waiting clarification"' do

          context 'when there is a last response' do

            let(:info_request){ FactoryBot.create(:info_request_with_incoming) }

            it 'should redirect to the "response url"' do
              session[:user_id] = info_request.user_id
              expected_url = new_request_incoming_followup_path(
                              :request_id => info_request.id,
                              :incoming_message_id =>
                                info_request.get_last_public_response.id)
              expect_redirect('waiting_clarification', expected_url)
              expect(flash[:notice][:partial]).
                to eq('request/describe_notices/waiting_clarification')
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
            expect_redirect('rejected',
              help_unhappy_path(info_request.url_title))
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/rejected')
          end

        end

        context 'when status is updated to "partially successful"' do

          it 'should redirect to the "unhappy url"' do
            expect_redirect('partially_successful',
                            help_unhappy_path(info_request.url_title))
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/partially_successful')
          end

        end

        context 'when status is updated to "gone postal"' do

          let(:info_request){ FactoryBot.create(:info_request_with_incoming) }

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
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/internal_review')
          end

        end

        context 'when status is updated to "requires admin"' do

          it 'should redirect to the "request url"' do
            patch :describe_state,
                  params: {
                    :incoming_message => {
                      :described_state => 'requires_admin',
                      :message => "A message"
                    },
                    :id => info_request.id,
                    :last_info_request_event_id =>
                      info_request.last_event_id_needing_description
                  }
            expect(response)
              .to redirect_to show_request_url(:url_title => info_request.url_title)
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/requires_admin')
          end

        end

        context 'when status is updated to "error message"' do

          it 'should redirect to the "request url"' do
            patch :describe_state,
                  params: {
                    :incoming_message => {
                      :described_state => 'error_message',
                      :message => "A message"
                    },
                    :id => info_request.id,
                    :last_info_request_event_id =>
                      info_request.last_event_id_needing_description
                  }
            expect(response)
              .to redirect_to(
                    show_request_url(:url_title => info_request.url_title)
                  )
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/error_message')
          end

          context "if the params don't include a message" do

            it 'redirects to the message url' do
              patch :describe_state,
                    params: {
                      :incoming_message => {
                        :described_state => "error_message"
                      },
                      :id => info_request.id,
                      :incoming_message_id =>
                        info_request.incoming_messages.last,
                      :last_info_request_event_id =>
                        info_request.last_event_id_needing_description
                    }
              expected_url = describe_state_message_url(
                               :url_title => info_request.url_title,
                               :described_state => 'error_message')
              expect(response).to redirect_to(expected_url)
            end

          end

        end

        context 'when status is updated to "user_withdrawn"' do

          let(:info_request){ FactoryBot.create(:info_request_with_incoming) }

          it 'should redirect to the "respond to last" url' do
            session[:user_id] = info_request.user_id
            expected_url = new_request_incoming_followup_path(
                            :request_id => info_request.id,
                            :incoming_message_id =>
                              info_request.get_last_public_response.id)
            expect_redirect('user_withdrawn', expected_url)
            expect(flash[:notice][:partial]).
                to eq('request/describe_notices/user_withdrawn')
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
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(response.body).to have_css("div#comment-1 h2") do |s|
      expect(s).to contain /Silly.*left an annotation/m
      expect(s).not_to contain /You.*left an annotation/m
    end
  end

  it "should link to the user who submitted to it, even if it is you" do
    session[:user_id] = users(:silly_name_user).id
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
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
    let(:embargoed_request){ FactoryBot.create(:embargoed_request)}

    it 'raises an ActiveRecord::RecordNotFound error' do
      expect {
        get :upload_response, params: { :url_title => embargoed_request.url_title }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  it "should require login to view the form to upload" do
    @ir = info_requests(:fancy_dog_request)
    expect(@ir.public_body.is_foi_officer?(@normal_user)).to eq(false)
    session[:user_id] = @normal_user.id

    get :upload_response, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to render_template('user/wrong_user')
  end

  it "should let you view upload form if you are an FOI officer" do
    @ir = info_requests(:fancy_dog_request)
    expect(@ir.public_body.is_foi_officer?(@foi_officer_user)).to eq(true)
    session[:user_id] = @foi_officer_user.id

    get :upload_response, params: { :url_title => 'why_do_you_have_such_a_fancy_dog' }
    expect(response).to render_template('request/upload_response')
  end

  it "should prevent uploads if you are not a requester" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.count
    session[:user_id] = @normal_user.id

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('/files/parrot.png','image/png')
    post :upload_response, params: {
                             :url_title => 'why_do_you_have_such_a_fancy_dog',
                             :body => "Find attached a picture of a parrot",
                             :file_1 => parrot_upload,
                             :submitted_upload_response => 1
                           }
    expect(response).to render_template('user/wrong_user')
  end

  it "should prevent entirely blank uploads" do
    session[:user_id] = @foi_officer_user.id

    post :upload_response, params: { :url_title => 'why_do_you_have_such_a_fancy_dog', :body => "", :submitted_upload_response => 1 }
    expect(response).to render_template('request/upload_response')
    expect(flash[:error]).to match(/Please type a message/)
  end

  it 'should 404 for non existent requests' do
    expect {
      post :upload_response, params: { :url_title => 'i_dont_exist' }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  # How do I test a file upload in rails?
  # http://stackoverflow.com/questions/1178587/how-do-i-test-a-file-upload-in-rails
  it "should let the authority upload a file" do
    @ir = info_requests(:fancy_dog_request)
    incoming_before = @ir.incoming_messages.count
    session[:user_id] = @foi_officer_user.id

    # post up a photo of the parrot
    parrot_upload = fixture_file_upload('/files/parrot.png','image/png')
    post :upload_response, params: {
                             :url_title => 'why_do_you_have_such_a_fancy_dog',
                             :body => "Find attached a picture of a parrot",
                             :file_1 => parrot_upload,
                             :submitted_upload_response => 1
                           }

    expect(response).to redirect_to(:action => 'show', :url_title => 'why_do_you_have_such_a_fancy_dog')
    expect(flash[:notice]).to match(/Thank you for responding to this FOI request/)

    # check there is a new attachment
    incoming_after = @ir.incoming_messages.count
    expect(incoming_after).to eq(incoming_before + 1)

    # check new attachment looks vaguely OK
    new_im = @ir.incoming_messages[-1]
    expect(new_im.get_main_body_text_unfolded).
      to match(/Find attached a picture of a parrot/)
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
    get :show, params: { :url_title => 'why_do_you_have_such_a_fancy_dog', :format => 'json' }

    ir = JSON.parse(response.body)
    expect(ir.class.to_s).to eq('Hash')

    expect(ir['url_title']).to eq('why_do_you_have_such_a_fancy_dog')
    expect(ir['public_body']['url_name']).to eq('tgq')
    expect(ir['user']['url_name']).to eq('bob_smith')
  end

end

describe RequestController, "when doing type ahead searches" do

  before :each do
    get_fixtures_xapian_index
  end

  it 'can filter search results by public body' do
    get :search_typeahead, params: { :q => 'boring', :requested_from => 'dfh' }
    expect(assigns[:query]).to eq('requested_from:dfh boring')
  end

  it 'defaults to 25 results per page' do
    get :search_typeahead, params: { :q => 'boring' }
    expect(assigns[:per_page]).to eq(25)
  end

  it 'can limit the number of searches returned' do
    get :search_typeahead, params: { :q => 'boring', :per_page => '1' }
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
    get :similar, params: {
                    :url_title => info_requests(:badger_request).url_title
                  }
    expect(response).to render_template("request/similar")
  end

  it 'assigns the request' do
    get :similar, params: {
                    :url_title => info_requests(:badger_request).url_title
                  }
    expect(assigns[:info_request]).to eq(info_requests(:badger_request))
  end

  it "assigns a xapian object with similar requests" do
    get :similar, params: { :url_title => badger_request.url_title }

    # Xapian seems to think *all* the requests are similar
    results = assigns[:xapian_object].results
    expected = InfoRequest.all.reject{ |request| request == badger_request }
    expect(results.map{ |result| result[:model].info_request })
      .to match_array(expected)
  end

  it "raises ActiveRecord::RecordNotFound for non-existent paths" do
    expect {
      get :similar, params: {
                      :url_title => "there_is_really_no_such_path_owNAFkHR"
                    }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "raises ActiveRecord::RecordNotFound for pages beyond the last
      page we want to show" do
    expect {
      get :similar, params: {
                      :url_title => badger_request.url_title,
                      :page => 100
                    }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'raises ActiveRecord::RecordNotFound if the request is embargoed' do
    badger_request.create_embargo(:publish_at => Time.zone.now + 3.days)
    expect {
      get :similar, params: { :url_title => badger_request.url_title }
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
    attachment = FactoryBot.build(:body_text, :filename => long_name)
    allow(IncomingMessage).to receive(:find).with("44").and_return(incoming_message)
    allow(IncomingMessage).to receive(:get_attachment_by_url_part_number_and_filename).and_return(attachment)
    allow(InfoRequest).to receive(:find).with("132").and_return(info_request)
    params = { :file_name => long_name,
               :controller => "request",
               :action => "get_attachment_as_html",
               :id => "132",
               :incoming_message_id => "44",
               :part => "2" }
    get :get_attachment_as_html, params: params
  end

end

describe RequestController, "#new_batch" do

  context "when batch requests is enabled" do

    before do
      allow(AlaveteliConfiguration).to receive(:allow_batch_requests).and_return(true)
    end

    context "when the current user can make batch requests" do

      before do
        @user = FactoryBot.create(:user, :can_make_batch_requests => true)
        @public_body = FactoryBot.create(:public_body)
        @other_public_body = FactoryBot.create(:public_body)
        @public_body_ids = [@public_body.id, @other_public_body.id]
        @default_post_params = { :info_request => { :title => "What does it all mean?",
                                                    :tag_string => "" },
                                 :public_body_ids => @public_body_ids,
                                 :outgoing_message => { :body => "This is a silly letter." },
                                 :submitted_new_request => 1,
                                 :preview => 1 }
      end

      it 'should be successful' do
        get :new_batch, params: { :public_body_ids => @public_body_ids },
                        session: { :user_id => @user.id }
        expect(response).to be_success
      end

      it 'should render the "new" template' do
        get :new_batch, params: { :public_body_ids => @public_body_ids },
                        session: { :user_id => @user.id }
        expect(response).to render_template('request/new')
      end

      it 'should redirect to "select_authorities" if no public_body_ids param is passed' do
        get :new_batch, session: { :user_id => @user.id }
        expect(response).to redirect_to select_authorities_path
      end

      it "should render 'preview' when given a good title and body" do
        post :new_batch, params: @default_post_params,
                         session: { :user_id => @user.id }
        expect(response).to render_template('preview')
      end

      it "should give an error and render 'new' template when a summary isn't given" do
        @default_post_params[:info_request].delete(:title)
        post :new_batch, params: @default_post_params,
                         session: { :user_id => @user.id }
        expect(assigns[:info_request].errors[:title]).to eq(['Please enter a summary of your request'])
        expect(response).to render_template('new')
      end

      it "should allow re-editing of a request" do
        params = @default_post_params.merge(:preview => 0, :reedit => 1)
        post :new_batch, params: params,
                         session: { :user_id => @user.id }
        expect(response).to render_template('new')
      end

      it "re-editing preserves the message body" do
        params = @default_post_params.merge(:preview => 0, :reedit => 1)
        post :new_batch, params: params,
                         session: { :user_id => @user.id }
        expect(assigns[:outgoing_message].body).
          to include('This is a silly letter.')
      end

      context "on success" do

        def make_request
          @params = @default_post_params.merge(:preview => 0)
          post :new_batch, params: @params,
                           session: { :user_id => @user.id }
        end

        it 'should create an info request batch and redirect to the new batch on success' do
          make_request
          new_info_request_batch = assigns[:info_request_batch]
          expect(new_info_request_batch).not_to be_nil
          expect(response).to redirect_to(info_request_batch_path(new_info_request_batch))
        end

        it 'should prevent double submission of a batch request' do
          make_request
          post :new_batch, params: @params,
                           session: { :user_id => @user.id }
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
          post :new_batch, params: @default_post_params,
                           session: { :user_id => @user.id }
          expect(response).to render_template('user/banned')
          expect(assigns[:details]).to eq('bad behaviour')
        end

      end

    end

    context "when the current user can't make batch requests" do

      render_views

      before do
        @user = FactoryBot.create(:user)
      end

      it 'should return a 403 with an appropriate message' do
        get :new_batch, session: { :user_id => @user.id }
        expect(response.code).to eq('403')
        expect(response.body).to match("Users cannot usually make batch requests to multiple authorities at once")
      end

    end

    context 'when there is no logged-in user' do

      it 'should return a redirect to the login page' do
        get :new_batch
        expect(response).
          to redirect_to(signin_path(:token => get_last_post_redirect.token))
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
        @user = FactoryBot.create(:user, :can_make_batch_requests => true)
      end

      context 'when asked for HTML' do

        it 'should be successful' do
          get :select_authorities, session: { :user_id => @user.id }
          expect(response).to be_success
        end

        it 'recognizes a GET request' do
          expect(:get => '/select_authorities').
            to route_to(:controller => 'request', :action => 'select_authorities')
        end

        it 'recognizes a POST request' do
          expect(:post => '/select_authorities').
            to route_to(:controller => 'request', :action => 'select_authorities')
        end

        it 'should render the "select_authorities" template' do
          get :select_authorities, session: { :user_id => @user.id }
          expect(response).to render_template('request/select_authorities')
        end

        it 'should assign a list of search results to the view if passed a query' do
          get :select_authorities, params: { :public_body_query => "Quango" },
                                   session: { :user_id => @user.id }
          expect(assigns[:search_bodies].results.size).to eq(1)
          expect(assigns[:search_bodies].results[0][:model].name).to eq(public_bodies(:geraldine_public_body).name)
        end

        it 'should assign a list of public bodies to the view if passed a list of ids' do
          get :select_authorities,
              params: {
                :public_body_ids => [public_bodies(:humpadink_public_body).id]
              },
              session: { :user_id => @user.id }
          expect(assigns[:public_bodies].size).to eq(1)
          expect(assigns[:public_bodies][0].name).to eq(public_bodies(:humpadink_public_body).name)
        end

        it 'should subtract a list of public bodies to remove from the list of bodies assigned to
                    the view' do
          get :select_authorities,
              params: {
                :public_body_ids => [
                  public_bodies(:humpadink_public_body).id,
                  public_bodies(:geraldine_public_body).id ],
                :remove_public_body_ids => [
                  public_bodies(:geraldine_public_body).id ]
              },
              session: { :user_id => @user.id }
          expect(assigns[:public_bodies].size).to eq(1)
          expect(assigns[:public_bodies][0].name).to eq(public_bodies(:humpadink_public_body).name)
        end

      end

      context 'when asked for JSON' do

        it 'should be successful' do
          get :select_authorities, params: { :public_body_query => "Quan",
                                             :format => 'json' },
                                   session: { :user_id => @user.id }
          expect(response).to be_success
        end

        it 'should return a list of public body names and ids' do
          get :select_authorities, params: { :public_body_query => "Quan",
                                             :format => 'json' },
                                   session: { :user_id => @user.id }

          expect(JSON(response.body)).to eq([{ 'id' => public_bodies(:geraldine_public_body).id,
                                           'name' => public_bodies(:geraldine_public_body).name }])
        end

        it 'should return an empty list if no search is passed' do
          get :select_authorities, params: { :format => 'json' },
                                   session: { :user_id => @user.id }
          expect(JSON(response.body)).to eq([])
        end

        it 'should return an empty list if there are no bodies' do
          get :select_authorities, params: { :public_body_query => 'fknkskalnr',
                                             :format => 'json' },
                                   session: { :user_id => @user.id }
          expect(JSON(response.body)).to eq([])
        end

      end

    end

    context "when the current user can't make batch requests" do

      render_views

      before do
        @user = FactoryBot.create(:user)
      end

      it 'should return a 403 with an appropriate message' do
        get :select_authorities, session: { :user_id => @user.id }
        expect(response.code).to eq('403')
        expect(response.body).to match("Users cannot usually make batch requests to multiple authorities at once")
      end

    end

    context 'when there is no logged-in user' do

      it 'should return a redirect to the login page' do
        get :select_authorities
        expect(response).
          to redirect_to(signin_path(:token => get_last_post_redirect.token))
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
    expect(flash[:notice][:partial]).
      to eq "general/read_only_annotations.html.erb"
  end

  context "when annotations are disabled" do
    before do
      allow(controller).to receive(:feature_enabled?).with(:annotations).and_return(false)
    end

    it "doesn't mention annotations in the flash message" do
      get :new
      expect(flash[:notice][:partial]).to eq "general/read_only.html.erb"
    end
  end
end

describe RequestController do

  describe 'GET #details' do

    let(:info_request){ FactoryBot.create(:info_request)}

    it 'renders the details template' do
      get :details, params: { :url_title => info_request.url_title }
      expect(response).to render_template('details')
    end

    it 'assigns the info_request' do
      get :details, params: { :url_title => info_request.url_title }
      expect(assigns[:info_request]).to eq(info_request)
    end

    it 'assigns columns' do
      get :details, params: { :url_title => info_request.url_title }
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
        get :details, params: { :url_title => info_request.url_title }
        expect(response.code).to eq("403")
      end

      it 'shows the hidden request template' do
        get :details, params: { :url_title => info_request.url_title }
        expect(response).to render_template("request/hidden")
      end

    end

    context 'when the request is embargoed' do

      before do
        info_request.create_embargo(:publish_at => Time.zone.now + 3.days)
      end

      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          get :details, params: { :url_title => info_request.url_title }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end


  end

end

describe RequestController do
  describe 'GET #describe_state_message' do
    let(:info_request){ FactoryBot.create(:info_request_with_incoming) }

    it 'assigns the info_request to the view' do
      get :describe_state_message, params: {
                                     :url_title => info_request.url_title,
                                     :described_state => 'error_message'
                                   }
      expect(assigns[:info_request]).to eq info_request
    end

    it 'assigns the described state to the view' do
      get :describe_state_message, params: {
                                     :url_title => info_request.url_title,
                                     :described_state => 'error_message'
                                   }
      expect(assigns[:described_state]).to eq 'error_message'
    end

    it 'assigns the last info request event id to the view' do
       get :describe_state_message, params: {
                                      :url_title => info_request.url_title,
                                      :described_state => 'error_message'
                                    }
      expect(assigns[:last_info_request_event_id])
        .to eq info_request.last_event_id_needing_description
    end

    it 'assigns the title to the view' do
      get :describe_state_message, params: {
                                     :url_title => info_request.url_title,
                                     :described_state => 'error_message'
                                   }
      expect(assigns[:title]).to eq "I've received an error message"
    end

    context 'when the request is embargoed' do
      let(:info_request){ FactoryBot.create(:embargoed_request) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :describe_state_message, params: {
                                         :url_title => info_request.url_title,
                                         :described_state => 'error_message'
                                       }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end
  end
end

describe RequestController do

  describe 'GET #download_entire_request' do
    context 'when the request is embargoed' do
      let(:user) { FactoryBot.create(:user) }
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:info_request) do
        FactoryBot.create(:embargoed_request, user: pro_user)
      end

      context 'and the user is not logged in' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :download_entire_request,
                params: { :url_title => info_request.url_title }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'and the user is logged in but not the owner' do
        before do
          session[:user_id] = user.id
        end

        it 'raises ActiveRecord::RecordNotFound' do
          expect {
            get :download_entire_request,
                params: { :url_title => info_request.url_title }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'and the user is the owner' do
        before do
          session[:user_id] = pro_user.id
        end

        it 'allows the download' do
          get :download_entire_request,
              params: { :url_title => info_request.url_title }
          expect(response).to be_success
        end
      end
    end

    context 'when the request is unclassified' do

      it 'does not render the describe state form' do
        info_request = FactoryBot.create(:info_request)
        info_request.update_attributes(:awaiting_description => true)
        info_request.expire
        session[:user_id] = info_request.user_id
        get :download_entire_request, params: { :url_title => info_request.url_title }
        expect(assigns[:show_top_describe_state_form]).to eq(false)
        expect(assigns[:show_bottom_describe_state_form]).to eq(false)
        expect(assigns[:show_owner_update_status_action]).to eq(false)
        expect(assigns[:show_other_user_update_status_action]).to eq(false)
        expect(assigns[:show_profile_photo]).to eq(false)
      end

    end

  end
end

describe RequestController do

  describe 'GET #show_request_event' do

    context 'when the event is an incoming message' do
      let(:event){ FactoryBot.create(:response_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the incoming message path' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response)
          .to redirect_to(incoming_message_path(event.incoming_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { :info_request_event_id => event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when the event is an outgoing message' do
      let(:event){ FactoryBot.create(:sent_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the outgoing message path' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response)
          .to redirect_to(outgoing_message_path(event.outgoing_message))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { :info_request_event_id => event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'for any other kind of event' do
      let(:event){ FactoryBot.create(:info_request_event) }

      it 'returns a 301 status' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response.status).to eq(301)
      end

      it 'redirects to the request path' do
        get :show_request_event, params: { :info_request_event_id => event.id }
        expect(response)
          .to redirect_to(show_request_path(event.info_request.url_title))
      end

      it 'raises ActiveRecord::RecordNotFound when the request is embargoed' do
        event.info_request.create_embargo(:publish_at => Time.zone.now + 1.day)
        expect {
          get :show_request_event, params: { :info_request_event_id => event.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'GET #search_typeahead' do

    it "does not raise an error if there are no params" do
      expect {
        get :search_typeahead
      }.not_to raise_error
    end

  end

end

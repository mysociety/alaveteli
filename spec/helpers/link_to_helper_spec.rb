require 'spec_helper'

describe LinkToHelper do
  include LinkToHelper

  describe 'when creating a url for a request' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'should return a path like /request/test_title' do
      expected = "/request/#{info_request.url_title}"
      expect(request_path(info_request)).to eq(expected)
    end

    it 'should return a path including any extra parameters passed' do
      expected = "/request/#{info_request.url_title}?update_status=1"
      actual = request_path(info_request, {:update_status => 1})
      expect(actual).to eq(expected)
    end
  end

  describe 'when linking to new incoming messages' do
    let(:incoming_message) { FactoryBot.create(:incoming_message) }
    let(:info_request) { incoming_message.info_request }

    context 'for external links' do
      subject(:url) { incoming_message_url(incoming_message) }

      it 'generates the url to the info request of the message' do
        expect(url).
          to include("http://test.host/request/#{info_request.url_title}")
      end

      it 'includes an anchor to the new message' do
        expect(url).to include("#incoming-#{incoming_message.id}")
      end

      it 'does not cache by default' do
        expect(url).not_to include("nocache=incoming-#{incoming_message.id}")
      end

      it 'includes a cache busting parameter if set' do
        url = incoming_message_url(incoming_message, :cachebust => true)
        expect(url).to include("nocache=incoming-#{incoming_message.id}")
      end

    end

    context 'for internal links' do
      subject(:path) { incoming_message_path(incoming_message) }

      it 'generates the incoming_message_url with the path only' do
        expected = "/request/#{info_request.url_title}" \
                   "#incoming-#{incoming_message.id}"
        expect(path).to eq(expected)
      end
    end
  end

  describe 'when linking to new responses' do
    context 'when the user is a pro' do
      let(:user) { FactoryBot.create(:pro_user) }
      let(:info_request) { FactoryBot.create(:info_request, user: user) }
      let(:incoming_message) do
        FactoryBot.create(:incoming_message, info_request: info_request)
      end

      it 'creates a sign in url to the cachebusted incoming message url' do
        msg_url = incoming_message_url(incoming_message, :cachebust => true)
        expected = signin_url(:r => msg_url)
        actual = new_response_url(info_request, incoming_message)
        expect(actual).to eq(expected)
      end
    end

    context 'when the user is a normal user' do
      let(:incoming_message) { FactoryBot.create(:incoming_message) }
      let(:info_request) { incoming_message.info_request }

      it 'creates a cachbusted incoming message url' do
        expected = incoming_message_url(incoming_message, :cachebust => true)
        actual = new_response_url(info_request, incoming_message)
        expect(actual).to eq(expected)
      end
    end
  end

  describe 'when linking to new outgoing messages' do
    let(:outgoing_message) { FactoryBot.create(:new_information_followup) }
    let(:info_request) { outgoing_message.info_request }

    subject(:url) { outgoing_message_url(outgoing_message) }

    context 'for external links' do
      it 'generates the url to the info request of the message' do
        expect(url).
          to include("http://test.host/request/#{info_request.url_title}")
      end

      it 'includes an anchor to the new message' do
        expect(url).to include("#outgoing-#{outgoing_message.id}")
      end

      it 'does not cache by default' do
        expect(url).not_to include("nocache=outgoing-#{outgoing_message.id}")
      end

      it 'includes a cache busting parameter if set' do
        url = outgoing_message_url(outgoing_message, :cachebust => true)
        expect(url).to include("nocache=outgoing-#{outgoing_message.id}")
      end
    end

    context 'for internal links' do
      it 'generates the outgoing_message_url with the path only' do
        expected = "/request/#{info_request.url_title}" \
                   "#outgoing-#{outgoing_message.id}"
        expect(outgoing_message_path(outgoing_message)).to eq(expected)
      end
    end
  end

  describe 'when displaying a user link for a request' do
    context "for external requests" do
      let(:info_request) do
        FactoryBot.create(:external_request, :external_user_name => nil)
      end

      it 'should return the text "Anonymous user" with a link to the privacy
          help pages when there is no external username' do
        expected = '<a href="/help/privacy#anonymous">Anonymous user</a>'
        expect(request_user_link(info_request)).to eq(expected)
      end

      it 'should return a link with an alternative text if requested' do
        expected = '<a href="/help/privacy#anonymous">other text</a>'
        actual = request_user_link(info_request, 'other text')
        expect(actual).to eq(expected)
      end

      it 'should display an absolute link if requested' do
        expected = '<a href="http://test.host/help/privacy#anonymous">' \
                   'Anonymous user</a>'
        expect(request_user_link_absolute(info_request)).to eq(expected)
      end
    end

    context "for normal requests" do
      let(:info_request) { FactoryBot.create(:info_request) }
      let(:user) { info_request.user }

      it 'should display a relative link by default' do
        expected = "<a href=\"/user/#{user.url_name}\">#{user.name}</a>"
        expect(request_user_link(info_request)).to eq(expected)
      end

      it 'should display an absolute link if requested' do
        expected = "<a href=\"http://test.host/user/#{user.url_name}\">" \
                   "#{user.name}</a>"
        expect(request_user_link_absolute(info_request)).to eq(expected)
      end
    end
  end

  describe 'when displaying a user admin link for a request' do
    let(:info_request) do
      FactoryBot.create(:external_request, :external_user_name => nil)
    end

    it 'should return the text "An anonymous user (external)" in the case
        where there is no external username' do
      expected = 'Anonymous user (external)'
      expect(user_admin_link_for_request(info_request)).to eq(expected)
    end
  end

  describe '#current_path_with_locale' do
    before do
      @was_routing_filter_active = RoutingFilter.active?
      RoutingFilter.active = true

      AlaveteliLocalization.set_locales('en cy', 'en')
    end

    after do
      RoutingFilter.active = @was_routing_filter_active
    end

    it 'prepends current path with new locale' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all'
        )
      )
      expect(current_path_with_locale('cy')).to eq '/cy/body/welsh_government'
    end

    it 'ignores current protocol and host' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all',
          protocol: 'http', host: 'example.com'
        )
      )
      expect(current_path_with_locale('cy')).to eq '/cy/body/welsh_government'
    end
  end

  describe '#current_path_as_json' do
    it 'appends current path with json format' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all'
        )
      )
      expect(current_path_as_json).to eq '/body/welsh_government.json'
    end

    it 'ignores current protocol and host' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all',
          protocol: 'http', host: 'example.com'
        )
      )
      expect(current_path_as_json).to eq '/body/welsh_government.json'
    end
  end
end

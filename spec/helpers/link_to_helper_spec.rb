require 'spec_helper'

RSpec.describe LinkToHelper do
  include LinkToHelper

  describe 'when creating a url for a request' do
    let(:info_request) { FactoryBot.create(:info_request) }

    it 'should return a path like /request/test_title' do
      expected = "/request/#{info_request.url_title}"
      expect(request_path(info_request)).to eq(expected)
    end

    it 'should return a path including any extra parameters passed' do
      expected = "/request/#{info_request.url_title}?update_status=1"
      actual = request_path(info_request, { update_status: 1 })
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
        url = incoming_message_url(incoming_message, cachebust: true)
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

    context 'when anchor only' do
      subject(:url) do
        incoming_message_url(incoming_message, anchor_only: true)
      end

      it 'returns an anchor to the new message' do
        expect(url).to eq("#incoming-#{incoming_message.id}")
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
        msg_url = incoming_message_url(incoming_message, cachebust: true)
        expected = signin_url(r: msg_url)
        actual = new_response_url(info_request, incoming_message)
        expect(actual).to eq(expected)
      end
    end

    context 'when the user is a normal user' do
      let(:incoming_message) { FactoryBot.create(:incoming_message) }
      let(:info_request) { incoming_message.info_request }

      it 'creates a cachbusted incoming message url' do
        expected = incoming_message_url(incoming_message, cachebust: true)
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
        url = outgoing_message_url(outgoing_message, cachebust: true)
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

    context 'when anchor only' do
      subject(:url) do
        outgoing_message_url(outgoing_message, anchor_only: true)
      end

      it 'returns an anchor to the new message' do
        expect(url).to eq("#outgoing-#{outgoing_message.id}")
      end
    end
  end

  describe 'when linking to attachments' do
    let(:info_request) do
      FactoryBot.create(:info_request, :with_plain_incoming)
    end
    let(:incoming_message) { info_request.incoming_messages.first }
    let(:attachment) { incoming_message.foi_attachments.first }

    context 'for external links' do
      subject { foi_attachment_url(attachment) }

      it 'generates the url to the info request of the message' do
        is_expected.to include \
          "http://test.host/request/#{info_request.url_title}"
      end

      it 'includes an anchor to the attachment' do
        is_expected.to include("#attachment-#{attachment.id}")
      end
    end

    context 'for internal links' do
      subject { foi_attachment_path(attachment) }

      it 'generates the outgoing_message_url with the path only' do
        is_expected.to eq \
          "/request/#{info_request.url_title}#attachment-#{attachment.id}"
      end
    end
  end

  describe 'when displaying a user link for a request' do
    context "for external requests" do
      let(:info_request) do
        FactoryBot.create(:external_request, external_user_name: nil)
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
      FactoryBot.create(:external_request, external_user_name: nil)
    end

    it 'should return the text "An anonymous user (external)" in the case
        where there is no external username' do
      expected = 'Anonymous user (external)'
      expect(user_admin_link_for_request(info_request)).to eq(expected)
    end
  end

  describe '#current_path_without_locale' do
    before do
      AlaveteliLocalization.set_locales('en cy', 'en')
    end

    it 'removes locale from current path' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all',
          locale: 'cy'
        )
      )
      expect(current_path_without_locale).
        to eq '/body/welsh_government'
    end

    it 'ignores current protocol and host' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all',
          protocol: 'http', host: 'example.com',
          locale: 'cy'
        )
      )
      expect(current_path_without_locale).
        to eq '/body/welsh_government'
    end
  end

  describe '#current_path_with_locale' do
    before do
      AlaveteliLocalization.set_locales('en cy', 'en')
    end

    it 'adds locale parameter to current path' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all'
        )
      )
      expect(current_path_with_locale('cy')).
        to eq '/body/welsh_government?locale=cy'
    end

    it 'ignores current protocol and host' do
      allow(controller).to receive(:params).and_return(
        ActionController::Parameters.new(
          controller: 'public_body', action: 'show',
          url_name: 'welsh_government', view: 'all',
          protocol: 'http', host: 'example.com'
        )
      )
      expect(current_path_with_locale('cy')).
        to eq '/body/welsh_government?locale=cy'
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

  describe '#incoming_message_dom_id' do
    subject { incoming_message_dom_id(incoming_message) }
    let(:incoming_message) { FactoryBot.create(:incoming_message) }

    context 'incoming message with main body part' do
      it 'returns main body part attachment dom ID' do
        main_body_part = incoming_message.get_main_body_text_part
        is_expected.to eq "attachment-#{main_body_part.to_param}"
      end
    end

    context 'incoming message without main body part' do
      before { allow(incoming_message).to receive(:get_main_body_text_part) }
      it { is_expected.to be_nil }
    end
  end

  describe '#add_query_params_to_url' do
    it 'adds new parameters to a URL without existing parameters' do
      url = 'http://example.com/'
      new_params = { foo: 1 }
      expect(add_query_params_to_url(url, new_params)).
        to eq 'http://example.com/?foo=1'
    end

    it 'adds ActiveModel object parameters to a URL by calling #to_param' do
      url = 'http://example.com/'
      new_params = { user: users(:bob_smith_user) }
      expect(add_query_params_to_url(url, new_params)).
        to eq 'http://example.com/?user=1'
    end

    it 'adds new parameters to a URL with existing parameters' do
      url = 'http://example.com/?bar=2'
      new_params = { foo: 1 }
      expect(add_query_params_to_url(url, new_params)).
        to eq 'http://example.com/?bar=2&foo=1'
    end

    it 'overwrites an existing parameter if a new value is provided' do
      url = 'http://example.com/?foo=2'
      new_params = { foo: 1 }
      expect(add_query_params_to_url(url, new_params)).
        to eq 'http://example.com/?foo=1'
    end

    it 'keeps existing url fragments' do
      url = 'http://example.com/#bar'
      new_params = { foo: 1 }
      expect(add_query_params_to_url(url, new_params)).
        to eq 'http://example.com/?foo=1#bar'
    end

    it 'handles special characters in parameter values' do
      url = 'http://example.com/'
      new_params = { special: 'chars like %&=' }
      updated_url = add_query_params_to_url(url, new_params)
      expect(URI.parse(updated_url).query).to eq 'special=chars+like+%25%26%3D'
    end

    it 'returns the original URL unchanged if no new parameters are provided' do
      url = 'http://example.com/?foo=1'
      new_params = {}
      expect(add_query_params_to_url(url, new_params)).to eq url
    end

    it 'does not error when URL is not RFC2396 compliant' do
      url = 'http://example.com/a url with spaces'
      new_params = { foo: 1 }
      expect { add_query_params_to_url(url, new_params) }.to_not raise_error
    end
  end
end

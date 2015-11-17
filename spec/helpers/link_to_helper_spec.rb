# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LinkToHelper do

  include LinkToHelper

  describe 'when creating a url for a request' do

    before do
      @mock_request = mock_model(InfoRequest, :url_title => 'test_title')
    end

    it 'should return a path like /request/test_title' do
      expect(request_path(@mock_request)).to eq('/request/test_title')
    end

    it 'should return a path including any extra parameters passed' do
      expect(request_path(@mock_request, {:update_status => 1})).to eq('/request/test_title?update_status=1')
    end

  end

  describe 'when linking to new incoming messages' do

    before do
      @info_request = mock_model(InfoRequest, :id => 123, :url_title => 'test_title')
      @incoming_message = mock_model(IncomingMessage, :id => 32, :info_request => @info_request)
    end

    context 'for external links' do

      it 'generates the url to the info request of the message' do
        expect(incoming_message_url(@incoming_message)).to include('http://test.host/request/test_title')
      end

      it 'includes an anchor to the new message' do
        expect(incoming_message_url(@incoming_message)).to include('#incoming-32')
      end

      it 'does not cache by default' do
        expect(incoming_message_url(@incoming_message)).not_to include('nocache=incoming-32')
      end

      it 'includes a cache busting parameter if set' do
        expect(incoming_message_url(@incoming_message, :cachebust => true)).to include('nocache=incoming-32')
      end

    end

    context 'for internal links' do

      it 'generates the incoming_message_url with the path only' do
        expected = '/request/test_title#incoming-32'
        expect(incoming_message_path(@incoming_message)).to eq(expected)
      end

    end

  end

  describe 'when linking to new outgoing messages' do

    before do
      @info_request = mock_model(InfoRequest, :id => 123, :url_title => 'test_title')
      @outgoing_message = mock_model(OutgoingMessage, :id => 32, :info_request => @info_request)
    end

    context 'for external links' do

      it 'generates the url to the info request of the message' do
        expect(outgoing_message_url(@outgoing_message)).to include('http://test.host/request/test_title')
      end

      it 'includes an anchor to the new message' do
        expect(outgoing_message_url(@outgoing_message)).to include('#outgoing-32')
      end

      it 'does not cache by default' do
        expect(outgoing_message_url(@outgoing_message)).not_to include('nocache=outgoing-32')
      end

      it 'includes a cache busting parameter if set' do
        expect(outgoing_message_url(@outgoing_message, :cachebust => true)).to include('nocache=outgoing-32')
      end

    end

    context 'for internal links' do

      it 'generates the outgoing_message_url with the path only' do
        expected = '/request/test_title#outgoing-32'
        expect(outgoing_message_path(@outgoing_message)).to eq(expected)
      end

    end

  end

  describe 'when displaying a user link for a request' do

    context "for external requests" do
      before do
        @info_request = mock_model(InfoRequest, :external_user_name => nil,
                                   :is_external? => true)
      end

      it 'should return the text "Anonymous user" with a link to the privacy help pages when there is no external username' do
        expect(request_user_link(@info_request)).to eq('<a href="/help/privacy#anonymous">Anonymous user</a>')
      end

      it 'should return a link with an alternative text if requested' do
        expect(request_user_link(@info_request, 'other text')).to eq('<a href="/help/privacy#anonymous">other text</a>')
      end

      it 'should display an absolute link if requested' do
        expect(request_user_link_absolute(@info_request)).to eq('<a href="http://test.host/help/privacy#anonymous">Anonymous user</a>')
      end
    end

    context "for normal requests" do

      before do
        @info_request = FactoryGirl.build(:info_request)
      end

      it 'should display a relative link by default' do
        expect(request_user_link(@info_request)).to eq('<a href="/user/example_user">Example User</a>')
      end

      it 'should display an absolute link if requested' do
        expect(request_user_link_absolute(@info_request)).to eq('<a href="http://test.host/user/example_user">Example User</a>')
      end

    end

  end

  describe 'when displaying a user admin link for a request' do

    it 'should return the text "An anonymous user (external)" in the case where there is no external username' do
      info_request = mock_model(InfoRequest, :external_user_name => nil,
                                :is_external? => true)
      expect(user_admin_link_for_request(info_request)).to eq('Anonymous user (external)')
    end

  end

end

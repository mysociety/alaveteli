# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LinkToHelper do

  include LinkToHelper

  describe 'when creating a url for a request' do

    before do
      @mock_request = mock_model(InfoRequest, :url_title => 'test_title')
    end

    it 'should return a path like /request/test_title' do
      request_path(@mock_request).should == '/request/test_title'
    end

    it 'should return a path including any extra parameters passed' do
      request_path(@mock_request, {:update_status => 1}).should == '/request/test_title?update_status=1'
    end

  end

  describe 'when linking to new incoming messages' do

    before do
      @info_request = mock_model(InfoRequest, :id => 123, :url_title => 'test_title')
      @incoming_message = mock_model(IncomingMessage, :id => 32, :info_request => @info_request)
    end

    context 'for external links' do

      it 'generates the url to the info request of the message' do
        incoming_message_url(@incoming_message).should include('http://test.host/request/test_title')
      end

      it 'includes an anchor to the new message' do
        incoming_message_url(@incoming_message).should include('#incoming-32')
      end

      it 'does not cache by default' do
        incoming_message_url(@incoming_message).should_not include('nocache=incoming-32')
      end

      it 'includes a cache busting parameter if set' do
        incoming_message_url(@incoming_message, :cachebust => true).should include('nocache=incoming-32')
      end

    end

    context 'for internal links' do

      it 'generates the incoming_message_url with the path only' do
        expected = '/request/test_title#incoming-32'
        incoming_message_path(@incoming_message).should == expected
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
        outgoing_message_url(@outgoing_message).should include('http://test.host/request/test_title')
      end

      it 'includes an anchor to the new message' do
        outgoing_message_url(@outgoing_message).should include('#outgoing-32')
      end

      it 'does not cache by default' do
        outgoing_message_url(@outgoing_message).should_not include('nocache=outgoing-32')
      end

      it 'includes a cache busting parameter if set' do
        outgoing_message_url(@outgoing_message, :cachebust => true).should include('nocache=outgoing-32')
      end

    end

    context 'for internal links' do

      it 'generates the outgoing_message_url with the path only' do
        expected = '/request/test_title#outgoing-32'
        outgoing_message_path(@outgoing_message).should == expected
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
        request_user_link(@info_request).should == '<a href="/help/privacy#anonymous">Anonymous user</a>'
      end

      it 'should return a link with an alternative text if requested' do
        request_user_link(@info_request, 'other text').should == '<a href="/help/privacy#anonymous">other text</a>'
      end

      it 'should display an absolute link if requested' do
        request_user_link_absolute(@info_request).should == '<a href="http://test.host/help/privacy#anonymous">Anonymous user</a>'
      end
    end

    context "for normal requests" do

      before do
        @info_request = FactoryGirl.build(:info_request)
      end

      it 'should display a relative link by default' do
        request_user_link(@info_request).should == '<a href="/user/example_user">Example User</a>'
      end

      it 'should display an absolute link if requested' do
        request_user_link_absolute(@info_request).should == '<a href="http://test.host/user/example_user">Example User</a>'
      end

    end

  end

  describe 'when displaying a user admin link for a request' do

    it 'should return the text "An anonymous user (external)" in the case where there is no external username' do
      info_request = mock_model(InfoRequest, :external_user_name => nil,
                                :is_external? => true)
      user_admin_link_for_request(info_request).should == 'Anonymous user (external)'
    end

  end

end

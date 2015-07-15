# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do

  include ApplicationHelper
  include LinkToHelper

  describe 'when creating an event description' do

    it 'should generate a description for a request' do
      @info_request = FactoryGirl.create(:info_request)
      @sent_event = @info_request.get_last_event
      expected = "Request sent to #{public_body_link_absolute(@info_request.public_body)} by #{request_user_link_absolute(@info_request)}"
      event_description(@sent_event).should match(expected)

    end

    it 'should generate a description for a response' do
      @info_request_with_incoming = FactoryGirl.create(:info_request_with_incoming)
      @response_event = @info_request_with_incoming.get_last_event
      expected = "Response by #{public_body_link_absolute(@info_request_with_incoming.public_body)} to #{request_user_link_absolute(@info_request_with_incoming)}"
      event_description(@response_event).should match(expected)
    end

    it 'should generate a description for a request where an internal review has been requested' do
      @info_request_with_internal_review_request = FactoryGirl.create(:info_request_with_internal_review_request)
      @response_event = @info_request_with_internal_review_request.get_last_event
      expected = "Internal review request sent to #{public_body_link_absolute(@info_request_with_internal_review_request.public_body)} by #{request_user_link_absolute(@info_request_with_internal_review_request)}"
      event_description(@response_event).should match(expected)
    end

  end

end

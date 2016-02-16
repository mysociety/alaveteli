# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'request/show' do

  let(:mock_body) { FactoryGirl.create(:public_body, :name => "test body") }

  let(:mock_user) do
    FactoryGirl.create(:user, :name => "test user",
                              :url_name => "test_user",
                              :profile_photo => nil)
  end

  let(:mock_request) do
    FactoryGirl.create(:info_request, :title => "Test request",
                                      :public_body => mock_body,
                                      :user => mock_user)
  end

  def request_page
    assign :info_request, mock_request
    assign :info_request_events, []
    assign :status, mock_request.calculate_status
    render
  end

  describe 'when a status update has been requested' do

    before do
      assign :update_status, true
    end

    it 'should show the first form for describing the state of the request' do
      request_page
      expect(response).to have_css("div.describe_state_form#describe_state_form_1")
    end

  end

  describe 'when it is awaiting a description' do

    before do
      allow(mock_request).to receive(:awaiting_description).and_return(true)
    end

    it 'should show the first form for describing the state of the request' do
      request_page
      expect(response).to have_css("div.describe_state_form#describe_state_form_1")
    end

    it 'should show the second form for describing the state of the request' do
      request_page
      expect(response).to have_css("div.describe_state_form#describe_state_form_2")
    end

  end

  describe 'when the user is the request owner' do

    before do
      assign :is_owning_user, true
    end

    describe 'when the request status is "waiting clarification"' do

      before do
        allow(mock_request).to receive(:calculate_status).and_return('waiting_clarification')
      end

      describe 'when there is a last response' do

        let(:mock_response) { FactoryGirl.create(:incoming_message) }

        it 'should show a link to follow up the last response with clarification' do
          allow(mock_request).to receive(:get_last_public_response).
            and_return(mock_response)
          request_page
          expected_url = new_request_incoming_followup_path(
                          :request_id => mock_request.id,
                          :incoming_message_id => mock_response.id)
          expect(response.body).
            to have_css(
              "a[href='#{expected_url}#followup']",
              :text => 'send a follow up message')
        end

      end

      describe 'when there is no last response' do

        before do
          allow(mock_request).to receive(:get_last_public_response).and_return(nil)
        end

        it 'should show a link to follow up the request without reference to a specific response' do
          request_page
          expected_url = new_request_followup_path(:request_id => mock_request.id)
          expect(response.body).
            to have_css(
              "a[href='#{expected_url}#followup']",
              :text => 'send a follow up message')
        end

      end

    end

  end

end

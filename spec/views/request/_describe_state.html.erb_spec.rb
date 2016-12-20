# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when showing the form for describing the state of a request' do
  let(:info_request) { FactoryGirl.create(:info_request) }
  let(:user) { info_request.user }

  def expect_radio_button(value)
    do_render
    expect(response.body).to have_css("input[type=radio][value=#{value}]")
  end

  def expect_no_radio_button(value)
    do_render
    expect(response.body).not_to have_css("input[type=radio][value=#{value}]")
  end

  def do_render
    render :partial => 'request/describe_state', :locals => {:id_suffix => '1'}
  end

  before do
    assign :info_request, info_request
    allow(view).to receive(:authenticated_user).and_return(user)
  end

  describe 'if the user is a regular user (not the request owner)' do
    before do
      assign :is_owning_user, false
      assign :state_transitions, info_request.state.transitions(
        is_owning_user: false,
        user_asked_to_update_status: false)
    end

    describe 'if the request is not old and unclassified' do
      it 'should not show the form' do
        do_render
        expect(response.body).not_to have_css('h2', :text => 'What best describes the status of this request now?')
      end

      it 'should give a link to login' do
        do_render
        expect(response.body).to have_css('a', :text => 'sign in')
      end
    end

    describe 'if the request is old and unclassified' do
      before do
        assign :old_unclassified, true
      end

      it 'should not show the form' do
        do_render
        expect(response.body).not_to have_css('h2', :text => 'What best describes the status of this request now?')
      end

      it 'should show the form for someone else to classify the request' do
        do_render
        expect(response.body).to have_css('h2', :text => 'We need your help')
      end

      it 'should not give a link to login' do
        do_render
        expect(response.body).not_to have_css('a', :text => 'sign in')
      end
    end
  end

  describe 'if showing the form to the user owning the request' do
    before do
      assign :is_owning_user, true
      assign :state_transitions, info_request.state.transitions(
        is_owning_user: true,
        user_asked_to_update_status: false)
    end

    describe 'when the request is not in internal review' do
      before do
        info_request.set_described_state('waiting_response')
        assign :state_transitions, info_request.state.transitions(
          is_owning_user: true,
          user_asked_to_update_status: false)
      end

      it 'should show a radio button to set the status to "waiting response"' do
        expect_radio_button('waiting_response')
      end

      it 'should show a radio button to set the status to "waiting clarification"' do
        expect_radio_button('waiting_clarification')
      end

      it 'should not show a radio button to set the status to "internal_review"' do
        expect_no_radio_button('internal_review')
      end
    end

    describe 'when the user has asked to update the status of the request' do
      before do
        assign :update_status, true
        assign :state_transitions, info_request.state.transitions(
          is_owning_user: true,
          user_asked_to_update_status: true)
      end

      it 'should show a radio button to set the status to "internal_review"' do
        expect_radio_button('internal_review')
      end

      it 'should show a radio button to set the status to "requires_admin"' do
        expect_radio_button('requires_admin')
      end

      it 'should show a radio button to set the status to "user_withdrawn"' do
        expect_radio_button('user_withdrawn')
      end
    end

    describe 'when the request is in internal review' do
      before do
        info_request.set_described_state('internal_review')
        assign :state_transitions, info_request.state.transitions(
          is_owning_user: true,
          user_asked_to_update_status: false)
      end

      it 'should show a radio button to set the status to "internal review"' do
        expect_radio_button('internal_review')
      end

      it 'should show the text "The review has finished and overall:"' do
        do_render
        expect(response).to have_css('p', :text => 'The review has finished and overall:')
      end
    end

    describe 'when request is awaiting a description and the user has not asked to update the status' do
    end

    it 'should show a radio button to set the status to "gone postal"' do
      expect_radio_button('gone_postal')
    end

    it 'should show a radio button to set the status to "not held"' do
      expect_radio_button('not_held')
    end

    it 'should show a radio button to set the status to "partially successful"' do
      expect_radio_button('partially_successful')
    end

    it 'should show a radio button to set the status to "successful"' do
      expect_radio_button('successful')
    end

    it 'should show a radio button to set the status to "rejected"' do
      expect_radio_button('rejected')
    end

    it 'should show a radio button to set the status to "error_message"' do
      expect_radio_button('error_message')
    end

    it 'should not show a radio button to set the status to "requires_admin"' do
      expect_no_radio_button('requires_admin')
    end

    it 'should not show a radio button to set the status to "user_withdrawn"' do
      expect_no_radio_button('user_withdrawn')
    end
  end
end

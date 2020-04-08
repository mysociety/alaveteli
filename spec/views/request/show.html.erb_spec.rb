# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe "request/show" do

  let(:mock_body) { FactoryBot.create(:public_body, :name => "test body") }

  let(:mock_user) do
    FactoryBot.create(:user, :name => "test user",
                             :url_name => "test_user",
                             :profile_photo => nil)
  end

  let(:admin_user) { FactoryBot.create(:admin_user) }

  let(:mock_request) do
    FactoryBot.create(:info_request, :title => "Test request",
                                     :public_body => mock_body,
                                     :user => mock_user)
  end

  let(:mock_track) do
    mock_model(TrackThing, :track_type => 'request_updates',
                           :info_request => mock_request)
  end

  def request_page
    assign :info_request, mock_request
    assign :info_request_events, []
    assign :status, mock_request.calculate_status
    assign :track_thing, mock_track
    assign :similar_requests, double.as_null_object
    assign :similar_more, double.as_null_object
    assign :citations, double.as_null_object

    allow(controller).
      to receive(:current_ability).and_return(double.as_null_object)
    allow(view).to receive(:current_user).and_return(double.as_null_object)

    render
  end

  it "should show the request" do
    request_page
    expect(rendered).to have_css("h1",:text => "Test request")
  end

  describe "when told to show the top describe state form" do
    before do
      assign :show_top_describe_state_form, true
    end

    it "should show the first form for describing the state of the request" do
      request_page
      expect(rendered).
        to have_css("div.describe_state_form#describe_state_form_1")
    end
  end

  describe "when told to show the bottom describe state form" do
    before do
      assign :show_bottom_describe_state_form, true
    end

    it "should show the second form for describing the state of the request" do
      request_page
      expect(rendered).
        to have_css("div.describe_state_form#describe_state_form_2")
    end
  end

  describe "when the user is the request owner" do
    before do
      assign :is_owning_user, true
    end

    context "and the request status is 'waiting clarification'" do
      before do
        allow(mock_request).to receive(:calculate_status).and_return("waiting_clarification")
      end

      context "and there is a last response" do
        let(:mock_response) { FactoryBot.create(:incoming_message) }

        it "should show a link to follow up the last response with clarification" do
          allow(mock_request).to receive(:get_last_public_response).
            and_return(mock_response)
          request_page
          expected_url = new_request_incoming_followup_path(
                          :request_id => mock_request.id,
                          :incoming_message_id => mock_response.id)
          expect(response.body).
            to have_css(
              "a[href='#{expected_url}#followup']",
              :text => "send a follow up message")
        end
      end

      context "and there is no last response" do
        before do
          allow(mock_request).to receive(:get_last_public_response).and_return(nil)
        end

        it "should show a link to follow up the request without reference to a specific response" do
          request_page
          expected_url = new_request_followup_path(:request_id => mock_request.id)
          expect(response.body).
            to have_css(
              "a[href='#{expected_url}#followup']",
              :text => "send a follow up message")
        end
      end
    end
  end

  describe "when the request is being viewed by an admin" do
    before :each do
      assign :user, admin_user
      # Admins own every request
      assign :is_owning_user, true

    end

    context "and the request is waiting for a response and very overdue" do
      before do
        allow(mock_request).
          to receive(:calculate_status).and_return("waiting_response_very_overdue")
        request_page
      end

      it "should give a link to requesting an internal review" do
        expect(response.body).to have_css(
          "div#request_status",
          :text => "requesting an internal review")
      end
    end

    context "and the request is waiting clarification" do
      before do
        allow(mock_request).
          to receive(:calculate_status).and_return("waiting_clarification")
        request_page
      end

      it "should give a link to make a followup" do
        expect(response.body).to have_css(
          "div#request_status a",
          :text => "send a follow up message")
      end
    end
  end

  describe "when showing an external request" do
    before :each do
      allow(mock_request).to receive(:is_external?).and_return("true")
      allow(mock_request).
        to receive(:awaiting_description?).and_return("true")
    end

    context 'when viewing anonymously' do
      it 'should not display actions the request owner can take' do
        request_page
        expect(response.body).not_to have_css('div#owner_actions')
      end
    end

    context 'when the request is being viewed by an admin' do
      before :each do
        assign :user, admin_user
      end

      context 'and the request is waiting for a response and very overdue' do
        before do
          allow(mock_request).
            to receive(:calculate_status).
              and_return('waiting_response_very_overdue')
          request_page
        end

        it 'should not give a link to requesting an internal review' do
          expect(rendered).not_to have_css(
            'p#request_status',
            :text => "requesting an internal review")
        end
      end

      context 'and the request is waiting clarification' do
        before do
          allow(mock_request).
            to receive(:calculate_status).and_return('waiting_clarification')
          request_page
        end

        it 'should not give a link to make a followup' do
          expect(rendered).not_to have_css(
            'p#request_status a',
            :text => "send a follow up message")
        end

        it 'should not give a link to sign in (in the request status <p>)' do
          expect(rendered).not_to have_css(
            'p#request_status a',
            :text => "sign in")
        end
      end
    end
  end

  describe 'when the authority is not subject to FOI law' do
    before do
      mock_body.add_tag_if_not_already_present('foi_no')
    end

    it 'displays a message that that authority is not obliged to respond' do
      request_page
      expect(rendered).
        to have_content('This authority is not subject to FOI law, so is not ' \
                        'legally obliged to respond')
    end

    context 'when the authority is only accepting EIR requests' do

      before do
        mock_body.add_tag_if_not_already_present('eir_only')
      end

      it 'displays a message that that authority is not obliged to respond' do
        request_page
        expect(rendered).
          to have_content('You only have a right in law to access ' \
                          'information about the environment from this ' \
                          'authority')
      end

    end

  end

  describe 'when the request is closed to new authority responses' do

    it 'displays to say that the request is closed to further correspondence' do
      mock_request.update_attribute(:allow_new_responses_from, 'nobody')
      request_page
      expect(rendered).
        to have_content('This request has been closed to new correspondence ' \
                        'from the public body. Contact us if you think it ' \
                        'ought be re-opened.')
    end

  end

  describe "censoring attachment names" do
    let(:request_with_attachment) do
      FactoryBot.create(:info_request_with_html_attachment)
    end

    before do
      allow(view).to receive(:current_user).and_return(nil)
      allow(controller).to receive(:current_user).and_return(nil)
    end

    context "when there isn't a censor rule" do
      it "should show the attachment name" do
        assign :info_request, request_with_attachment
        assign :info_request_events, request_with_attachment.info_request_events
        assign :status, request_with_attachment.calculate_status
        assign :track_thing, TrackThing.create_track_for_request(request_with_attachment)
        render
        expect(rendered).to have_css(".attachment .attachment__name") do |s|
          expect(s).to contain /interesting.pdf/m
        end
      end
    end

    context "when there is a censor rule" do
      it "should replace the attachment name" do
        request_with_attachment.censor_rules.create!(
          :text => "interesting.pdf",
          :replacement => "Mouse.pdf",
          :last_edit_editor => "unknown",
          :last_edit_comment => "none")
        assign :info_request, request_with_attachment
        assign :info_request_events, request_with_attachment.info_request_events
        assign :status, request_with_attachment.calculate_status
        assign :track_thing, TrackThing.create_track_for_request(request_with_attachment)
        # For cancancan
        allow(view).to receive(:current_user).and_return(nil)
        allow(controller).to receive(:current_user).and_return(nil)
        render
        # Note that the censor rule applies to the original filename,
        # not the display_filename:
        expect(rendered).to have_css(".attachment .attachment__name") do |s|
          expect(s).to contain /Mouse.pdf/m
        end
      end
    end
  end

  describe "follow links" do
    context "when the request being shown by public token" do
      it "should not show a follow link" do
        request_page
        expect(rendered).to_not have_css("a", text: "Follow")
      end
    end

    context "when the request is a normal request" do
      it "should show a follow link in action menu" do
        assign :show_action_menu, true
        request_page
        expect(rendered).to have_css("a", text: "Follow")
      end
    end

    context "when the request is a pro request" do
      it "should not show a follow link" do
        assign :in_pro_area, true
        request_page
        expect(rendered).not_to have_css("a", text: "Follow")
      end
    end
  end

  context 'when sidebar is true' do
    before do
      assign :sidebar, true
      assign :sidebar_template, 'sidebar'
    end

    it 'renders the sidebar' do
      request_page
      expect(rendered).to render_template(partial: '_sidebar')
    end
  end

  context 'when sidebar is false' do
    before do
      assign :sidebar, false
      assign :sidebar_template, 'sidebar'
    end

    it 'does not render the sidebar' do
      request_page
      expect(rendered).not_to render_template(partial: '_sidebar')
    end
  end
end

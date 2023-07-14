require 'spec_helper'
require 'integration/alaveteli_dsl'

RSpec.describe "When administering the site" do
  let(:admin_user) { FactoryBot.create(:admin_user) }
  let(:bob_smith_user) { FactoryBot.create(:user, name: 'Bob Smith') }
  let(:robin_user) { FactoryBot.create(:user, name: 'Robin') }

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it "allows an admin to log in as another user" do
    using_session(@admin) do
      visit admin_user_path bob_smith_user
      find_link('Log in as Bob Smith (also confirms their email)').click
      expect(page).to have_content 'Bob Smith'
    end
  end

  it 'does not allow a non-admin user to login as another user' do
    robin = login(:robin_user)
    using_session(robin) do
      visit admin_user_path bob_smith_user
      expect(page).to have_content \
        'To log into the administrative interface, please sign in as a superuser'
    end
  end

  it "allows redelivery of an incoming message to a closed request" do

    # close request
    info_request = FactoryBot.create(:info_request_with_incoming)
    close_request(info_request)

    # check number of messages in holding pen and request
    expect(holding_pen_messages.length).to eq(0)
    expect(info_request.incoming_messages.length).to eq(1)

    # deliver an incoming message to the closed request -
    # it gets bounced to the holding pen
    receive_incoming_mail('incoming-request-plain.email',
                          email_to: info_request.incoming_email,
                          email_from: "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)
    new_message = holding_pen_messages.first
    expect(info_request.incoming_messages.length).to eq(1)

    # redeliver the message
    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_message)
      fill_in('Redeliver message to one or more other requests',
                with: info_request.url_title)
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(info_request))
    end

    # check number of messages in holding pen and request
    expect(info_request.reload.incoming_messages.length).to eq(2)
    expect(holding_pen_messages.length).to eq(0)
  end

  it "allows redelivery of an incoming message to more than one request" do
    # close request
    info_request = FactoryBot.create(:info_request_with_incoming)
    close_request(info_request)

    # check number of messages in holding pen and requests
    expect(holding_pen_messages.length).to eq(0)
    expect(info_request.incoming_messages.length).to eq(1)

    second_request = FactoryBot.create(:info_request_with_incoming)
    expect(second_request.incoming_messages.length).to eq(1)

    # deliver an incoming message to the closed request -
    # it gets bounced to the holding pen
    receive_incoming_mail('incoming-request-plain.email',
                          email_to: info_request.incoming_email,
                          email_from: "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)
    new_message = holding_pen_messages.first

    # redeliver the message to two requests
    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_message)
      fill_in('Redeliver message to one or more other requests',
                 with: "#{info_request.url_title},#{second_request.url_title}")
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(second_request))
    end

    # check number of messages in holding pen and requests
    expect(info_request.reload.incoming_messages.length).to eq(2)
    expect(second_request.reload.incoming_messages.length).to eq(2)
    expect(holding_pen_messages.length).to eq(0)
  end

  describe "the debug page" do
    it "should show the current user name" do
      using_session(@admin) do
        visit admin_debug_path
        expect(page).to have_content "joe_admin"
      end
    end

    it "should show the current Alaveteli version" do
      using_session(@admin) do
        visit admin_debug_path
        expect(page).to have_content ALAVETELI_VERSION
      end
    end
  end

  describe 'when administering the holding pen' do

    it "shows a rejection reason for an incoming message from an invalid address" do
      info_request = FactoryBot.create(:info_request,
                                       allow_new_responses_from: 'authority_only',
                                       handle_rejected_responses: 'holding_pen')
      receive_incoming_mail('incoming-request-plain.email',
                            email_to: info_request.incoming_email,
                            email_from: "frob@nowhere.com")
      using_session(@admin) do
        visit admin_raw_email_path last_holding_pen_mail
        expect(page).to have_content "Only the authority can reply to this request"
      end
    end
  end

  describe 'generating an upload url' do

    it 'shows a flash message with instructions on forwarding the url' do
      request = FactoryBot.create(:info_request)
      authority_name = request.public_body.name
      authority_email = request.public_body.request_email

      using_session(@admin) do
        visit admin_request_path id: request.id
        find_button('Generate URL').click

        url = confirm_url(PostRedirect.last.email_token)

        message = "Send \"#{authority_name}\" <#{authority_email}> " \
                  "this URL: #{url} - it will log them in and let " \
                  "them upload a response to this request."

        expect(page).to have_link(authority_email,
                                  href: "mailto:#{authority_email}")
        expect(page).to have_link(url, href: url)
        expect(page).to have_content(message)
      end

    end

  end

  describe 'hide and notify' do

    let(:user) { FactoryBot.create(:user, name: "Awkward > Name") }
    let(:request) { FactoryBot.create(:info_request, user: user) }

    it 'sets the prominence of the request to requester_only' do
      using_session(@admin) do
        visit admin_request_path id: request.id
        choose('reason_not_foi_not_foi')
        find_button('Hide request').click
      end

      request.reload
      expect(request.prominence).to eq('requester_only')
    end

    it 'renders a message to confirm the requester has been notified' do
      using_session(@admin) do
        visit admin_request_path id: request.id
        choose('reason_not_foi_not_foi')
        find_button('Hide request').click
        expect(page).
          to have_content('Your message to Awkward > Name has been sent')
      end
    end

  end

end

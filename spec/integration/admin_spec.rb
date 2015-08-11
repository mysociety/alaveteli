# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When administering the site" do

  before do
    allow(AlaveteliConfiguration).to receive(:skip_admin_auth).and_return(false)
    confirm(:admin_user)
    @admin = login(:admin_user)
  end

  it "allows an admin to log in as another user" do
    using_session(@admin) do
      visit admin_user_path users(:bob_smith_user)
      find_button('Log in as Bob Smith (also confirms their email)').click
      expect(page).to have_content 'Hello, Bob Smith!'
    end
  end

  it 'does not allow a non-admin user to login as another user' do
    robin = login(:robin_user)
    using_session(robin) do
      visit admin_user_path users(:bob_smith_user)
      expect(page).to have_content \
        'To log into the administrative interface, please sign in as a superuser'
    end
  end

  it "allows redelivery of an incoming message to a closed request" do

    # close request
    info_request = info_requests(:fancy_dog_request)
    close_request(info_request)

    # check number of messages in holding pen and request
    expect(holding_pen_messages.length).to eq(0)
    expect(info_request.incoming_messages.length).to eq(1)

    # deliver an incoming message to the closed request -
    # it gets bounced to the holding pen
    receive_incoming_mail('incoming-request-plain.email',
                          info_request.incoming_email,
                          "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)
    new_message = holding_pen_messages.first
    expect(info_request.incoming_messages.length).to eq(1)

    # redeliver the message
    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_message)
      fill_in('Redeliver message to one or more other requests',
                :with => info_request.url_title)
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(info_request))
    end

    # check number of messages in holding pen and request
    expect(info_request.reload.incoming_messages.length).to eq(2)
    expect(holding_pen_messages.length).to eq(0)
  end

  it "allows redelivery of an incoming message to more than one request" do
    # close request
    info_request = info_requests(:fancy_dog_request)
    close_request(info_request)

    # check number of messages in holding pen and requests
    expect(holding_pen_messages.length).to eq(0)
    expect(info_request.incoming_messages.length).to eq(1)

    second_request = info_requests(:another_boring_request)
    expect(second_request.incoming_messages.length).to eq(1)

    # deliver an incoming message to the closed request -
    # it gets bounced to the holding pen
    receive_incoming_mail('incoming-request-plain.email',
                          info_request.incoming_email,
                          "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)
    new_message = holding_pen_messages.first

    # redeliver the message to two requests
    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_message)
      fill_in('Redeliver message to one or more other requests',
                 :with => "#{info_request.url_title},#{second_request.url_title}")
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(second_request))
    end

    # check number of messages in holding pen and requests
    expect(info_request.reload.incoming_messages.length).to eq(2)
    expect(second_request.reload.incoming_messages.length).to eq(2)
    expect(holding_pen_messages.length).to eq(0)
  end

  describe 'when administering the holding pen' do

    it "shows a rejection reason for an incoming message from an invalid address" do
      info_request = FactoryGirl.create(:info_request,
                                        :allow_new_responses_from => 'authority_only',
                                        :handle_rejected_responses => 'holding_pen')
      receive_incoming_mail('incoming-request-plain.email',
                            info_request.incoming_email,
                            "frob@nowhere.com")
      using_session(@admin) do
        visit admin_raw_email_path last_holding_pen_mail
        expect(page).to have_content "Only the authority can reply to this request"
      end
    end

    it "guesses a misdirected request" do
      info_request = FactoryGirl.create(:info_request,
                                        :allow_new_responses_from => 'authority_only',
                                        :handle_rejected_responses => 'holding_pen')
      mail_to = "request-#{info_request.id}-asdfg@example.com"
      receive_incoming_mail('incoming-request-plain.email', mail_to)
      interesting_email = last_holding_pen_mail

      # now we add another message to the queue, which we're not interested in
      receive_incoming_mail('incoming-request-plain.email', info_request.incoming_email, "")
      expect(holding_pen_messages.length).to eq(2)
      using_session(@admin) do
        visit admin_raw_email_path interesting_email
        expect(page).to have_content "Could not identify the request"
        expect(page).to have_content info_request.title
      end
    end
  end
end

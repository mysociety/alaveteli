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
    ir = info_requests(:fancy_dog_request)
    close_request(ir)
    expect(holding_pen_messages.length).to eq(0)
    expect(ir.incoming_messages.length).to eq(1)
    receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)
    new_im = holding_pen_messages[0]
    expect(ir.incoming_messages.length).to eq(1)
    post_params = { 'url_title' => ir.url_title }

    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_im)
      fill_in('Redeliver message to one or more other requests',
                :with => ir.url_title)
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(ir))
    end
    ir = InfoRequest.find_by_url_title(ir.url_title)
    expect(ir.incoming_messages.length).to eq(2)

    expect(holding_pen_messages.length).to eq(0)
  end

  it "allows redelivery of an incoming message to more than one request" do

    ir1 = info_requests(:fancy_dog_request)
    close_request(ir1)
    expect(ir1.incoming_messages.length).to eq(1)
    ir2 = info_requests(:another_boring_request)
    expect(ir2.incoming_messages.length).to eq(1)

    receive_incoming_mail('incoming-request-plain.email', ir1.incoming_email, "frob@nowhere.com")
    expect(holding_pen_messages.length).to eq(1)

    new_im = holding_pen_messages[0]


    using_session(@admin) do
      visit edit_admin_incoming_message_path(new_im)
      fill_in('Redeliver message to one or more other requests',
                 :with => "#{ir1.url_title},#{ir2.url_title}")
      find_button('Redeliver to another request').click
      expect(current_path).to eq(admin_request_path(ir2))
    end

    ir1.reload
    expect(ir1.incoming_messages.length).to eq(2)
    ir2.reload
    expect(ir2.incoming_messages.length).to eq(2)
    expect(@admin.response.location).to eq('http://www.example.com/en/admin/requests/106')
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
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
      expect(holding_pen_messages.length).to eq(2)
      using_session(@admin) do
        visit admin_raw_email_path interesting_email
        expect(page).to have_content "Could not identify the request"
        expect(page).to have_content ir.title
      end
    end


  end
end

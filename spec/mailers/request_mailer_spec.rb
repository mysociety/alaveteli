require 'spec_helper'

RSpec.describe RequestMailer do
  describe "when receiving incoming mail" do
    it "should not mutilate long URLs when trying to word wrap them" do
      long_url = 'http://www.this.is.quite.a.long.url.flourish.org/there.is.no.way.it.is.short.whatsoever'
      body = "This is a message with quite a long URL in it. It also has a paragraph, being this one that has quite a lot of text in it to. Enough to test the wrapping of itself.

#{long_url}

  And a paragraph afterwards."
      wrapped = MySociety::Format.wrap_email_body_by_paragraphs(body)
      expect(wrapped).to include(long_url)
    end
  end

  describe 'when sending emails' do
    it 'renders the footer partial for a user email' do
      expect_any_instance_of(RequestMailer).to receive(:set_footer_template)
      info_request = FactoryBot.create(:waiting_clarification_info_request)
      info_request.update_column(:updated_at, Time.zone.now - 5.days)
      RequestMailer.alert_not_clarified_request
    end

    it 'does not render the footer partial for a non-user email' do
      expect_any_instance_of(RequestMailer).not_to receive(:set_footer_template)
      info_request = FactoryBot.create(:info_request_with_incoming)
      mail = RequestMailer.
               fake_response(info_request,
                             mock_model(User, name_and_email: "test"),
                             "The body of the email...",
                             "blah.txt",
                             "The content of blah.txt")
      mail.message
    end
  end

  describe "when sending reminders to requesters to classify a response to their request" do
    let(:old_request) do
      InfoRequest.destroy_all
      FactoryBot.create(:old_unclassified_request)
    end

    def send_alerts
      RequestMailer.alert_new_response_reminders_internal(7, 'new_response_reminder_1')
    end

    def sent_alert_params(request, type)
      { info_request_id: request.id,
       user_id: request.user.id,
       info_request_event_id: request.get_last_public_response_event_id,
       alert_type: type }
    end

    it 'should raise an error if a request does not have a last response event id' do
      old_request.info_request_events.clear
      old_request.save!
      expected_message = "internal error, no last response while making alert " \
                         "new response reminder, request id #{old_request.id}"
      expect { send_alerts }.to raise_error(expected_message)
    end

    context 'if the request is embargoed' do
      it 'sends the reminder' do
        old_request.create_embargo(publish_at: Time.zone.now + 3.days)
        send_alerts
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries[0]
        expect(mail.body).to match(/#{old_request.title}/)
        expect(mail.body).to match(/Letting everyone know whether you got the information/)
      end
    end

    context 'if an alert matching the attributes of the reminder to be sent has already been sent' do
      it 'should not send the reminder' do
        params = sent_alert_params(old_request, 'new_response_reminder_1')
        UserInfoRequestSentAlert.create!(params)
        expect(RequestMailer).not_to receive(:new_response_reminder_alert)
        send_alerts
      end
    end

    context 'if no alert matching the attributes of the reminder to be sent has already been sent' do
      before do
        allow(UserInfoRequestSentAlert).to receive(:find).and_return(nil)
      end

      it 'should store the information that the reminder has been sent' do
        old_request
        send_alerts
        expect(UserInfoRequestSentAlert.where(sent_alert_params(old_request, 'new_response_reminder_1'))).not_to be_empty
      end

      it 'should send the reminder' do
        send_alerts
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries[0]
        expect(mail.body).to match(/Letting everyone know whether you got the information/)
      end
    end

    context "if the request has use_notifications set to true" do
      it "doesn't send the reminder" do
        old_request.use_notifications = true
        old_request.save!
        expect(RequestMailer).not_to receive(:new_response_reminder_alert)
        send_alerts
      end
    end
  end

  describe "when generating a fake response for an upload" do
    before do
      @foi_officer = mock_model(User, name_and_email: "FOI officer's name and email")
      @request_user = mock_model(User)
      @public_body = mock_model(PublicBody, name: 'Test public body')
      @info_request = mock_model(InfoRequest, user: @request_user,
                                 email_subject_followup: 'Re: Freedom of Information - Test request',
                                 incoming_name_and_email: 'Someone <someone@example.org>')
    end

    it 'should should generate a "fake response" email with a reasonable subject line' do
      fake_email = RequestMailer.fake_response(@info_request,
                                               @foi_officer,
                                               "The body of the email...",
                                               "blah.txt",
                                               "The content of blah.txt")
      expect(fake_email.subject).to eq("Re: Freedom of Information - Test request")
    end
  end

  describe "when sending a new response email" do
    let(:user) do
      FactoryBot.create(:user, name: "test name",
                               email: "email@localhost")
    end

    let(:public_body) do
      FactoryBot.create(:public_body, name: "Test public body")
    end

    let(:info_request) do
      FactoryBot.create(:info_request,
                        user: user,
                        title: "Here is a character that needs quoting …",
                        public_body: public_body,
                        described_state: 'rejected',
                        url_title: "test_request")
    end

    let(:incoming_message) do
      FactoryBot.create(:incoming_message, info_request: info_request)
    end

    it 'should not error when sending mails requests with characters requiring quoting in the subject' do
      mail = RequestMailer.new_response(info_request, incoming_message)
    end

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.new_response(FactoryBot.create(:info_request, title: "Here's a request"), FactoryBot.create(:incoming_message))
      expect(mail.subject).to eq "New response to your FOI request - Here's a request"
    end

    context "when the user does not use default locale" do
      before do
        info_request.title = "A request"
        info_request.user.locale = 'es'
      end

      it "translates the subject" do
        mail = RequestMailer.new_response(
          info_request,
          FactoryBot.create(:incoming_message)
        )
        expect(mail.subject).to eq(
          "Nueva respuesta a tu solicitud de información - A request"
        )
      end
    end

    it 'should send pro users a signin link' do
      pro_user = FactoryBot.create(:pro_user)
      info_request = FactoryBot.create(:embargoed_request, user: pro_user)
      incoming_message = FactoryBot.create(:incoming_message,
                                           info_request: info_request)
      mail = RequestMailer.new_response(info_request, incoming_message)
      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1

      message_url = incoming_message_url(incoming_message, cachebust: true)
      expected_url = signin_url(r: message_url)
      expect(mail_url).to eq expected_url
    end

    it 'should send normal users a direct link' do
      mail = RequestMailer.new_response(info_request, incoming_message)
      mail.body.to_s =~ /(http:\/\/\S*)/
      mail_url = $1
      expected_url = incoming_message_url(incoming_message, cachebust: true)
      expect(mail_url).to eq expected_url
    end
  end

  describe "sending unclassified new response reminder alerts" do
    it "sends an alert" do
      RequestMailer.alert_new_response_reminders
      info_request = info_requests(:fancy_dog_request)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(3) # sufficiently late it sends reminders too
      mail = deliveries[0]
      expect(mail.body).to match(/To let everyone know/)
      expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)
      expect(mail.subject).to eq(
        "Please update the status of your request - "\
        "Why do you have & such a fancy dog?"
      )

      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1

      redirect_target = show_request_path(
        info_request.url_title, anchor: 'describe_state_form_1'
      )

      expect(mail_url).to eq(signin_url(r: redirect_target))

      # Check anchor tag goes to last new response
      # Split on %23 as the redirect is URL encoded
      expect(mail_url.split('%23').last).to eq('describe_state_form_1')
    end

    context "when the user does not use default locale" do
      before do
        user = users(:bob_smith_user)
        @old_locale = user.locale
        user.locale = 'es'
        user.save
        RequestMailer.alert_new_response_reminders
      end

      after do
        user = users(:bob_smith_user)
        user.locale = @old_locale
        user.save
      end

      it "translates the subject" do
        expect(ActionMailer::Base.deliveries[0].subject).to eq(
          "*** Spanish missing *** "\
          "Why do you have & such a fancy dog?"
        )
      end
    end
  end

  describe "requires_admin" do
    let(:user) do
      FactoryBot.create(:user, name: "Bruce Jones",
                               email: "bruce@example.com")
    end

    let(:info_request) do
      FactoryBot.create(:info_request, user: user,
                                       title: "It's a Test request",
                                       url_title: "test_request",
                                       id: 123)
    end

    before do
      info_request.described_state = 'error_message'
      info_request.save!
    end

    it "body should contain the message from the user" do
      mail = RequestMailer.
        requires_admin(info_request, nil, "Something has gone wrong").
          deliver_now
      expect(mail.body).to include 'Something has gone wrong'
    end

    it 'should not create HTML entities in the subject line' do
      expect(RequestMailer.requires_admin(info_request).subject).
        to eq "FOI response requires admin (error_message) - It's a Test request"
    end

    it 'sets the "Reply-To" header header to the sender' do
      expect(RequestMailer.requires_admin(info_request).header['Reply-To'].to_s).
        to eq('Bruce Jones <bruce@example.com>')
    end

    it 'sets the "Return-Path" header to the blackhole address' do
      expect(RequestMailer.requires_admin(info_request).header['Return-Path'].to_s).
        to eq('do-not-reply-to-this-address@localhost')
    end

    context "when the user is not a pro" do
      it "sends the request to the normal contact address" do
        expect(RequestMailer.requires_admin(info_request).to).
          to eq([AlaveteliConfiguration.contact_email])
      end
    end

    context "when the user is a pro" do
      let(:pro_user) { FactoryBot.create(:pro_user) }
      let(:pro_request) { FactoryBot.create(:info_request, user: pro_user) }

      it "sends the request to the pro contact address" do
        with_feature_enabled(:alaveteli_pro) do
          expect(RequestMailer.requires_admin(pro_request).to).
            to eq([AlaveteliConfiguration.pro_contact_email])
        end
      end
    end
  end

  describe "sending overdue request alerts", focus: true do
    before(:each) do
      @kitten_request = FactoryBot.create(:info_request,
                                          title: "Do you really own a kitten?")
    end

    def kitten_mails
      ActionMailer::Base.deliveries.select { |mail| mail.body =~ /kitten/ }
    end

    it 'should not create HTML entities in the subject line' do
      info_request = FactoryBot.create(:info_request,
                                       title: "Here's a request")
      mail = RequestMailer.overdue_alert(info_request, info_request.user)
      expect(mail.subject).to eq "Delayed response to your FOI request - Here's a request"
    end

    context "when the user does not use default locale" do
      before do
        @info_request = FactoryBot.create(:info_request, title: "A request")
        @info_request.user.locale = 'es'
        @mail = RequestMailer.overdue_alert(@info_request, @info_request.user)
      end

      it "translates the subject" do
        expect(@mail.subject).to eq(
          "Respuesta retrasada a tu solicitud de acceso a información - "\
          "A request"
        )
      end
    end

    it "sends an overdue alert mail to request creators" do
      travel_to(31.days.from_now) do
        RequestMailer.alert_overdue_requests

        expect(kitten_mails.size).to eq(1)
        mail = kitten_mails[0]

        expect(mail.body).to match(/promptly, as normally/)
        expect(mail.to_addrs.first.to_s).to eq(@kitten_request.user.email)

        mail.body.to_s =~ /(http:\/\/.*)/
        mail_url = $1

        expect(mail_url).to match(
          new_request_followup_path(
            request_url_title: @kitten_request.url_title
          )
        )
      end
    end

    it "does not send the alert if the user is banned but records it as sent" do
      travel_to(31.days.from_now) do
        user = @kitten_request.user
        user.ban_text = 'Banned'
        user.save!
        expect(UserInfoRequestSentAlert.where(user_id: user.id).count).to eq(0)
        RequestMailer.alert_overdue_requests

        expect(kitten_mails.size).to eq(0)
        expect(UserInfoRequestSentAlert.where(user_id: user.id).count).to be > 0
      end
    end

    it "does not resend alerts to people who've already received them" do
      travel_to(31.days.from_now) do
        RequestMailer.alert_overdue_requests
        expect(kitten_mails.size).to eq(1)
        ActionMailer::Base.deliveries.clear
        RequestMailer.alert_overdue_requests
        expect(kitten_mails.size).to eq(0)
      end
    end

    it "sends alerts for requests where the last event forming the initial
          request is a followup being sent following a request for clarification" do
      # Request is waiting clarification
      @kitten_request.set_described_state('waiting_clarification')

      # Followup message is sent
      outgoing_message = OutgoingMessage.new(status: 'ready',
                                             message_type: 'followup',
                                             info_request_id: @kitten_request.id,
                                             body: 'Some text',
                                             what_doing: 'normal_sort')

      outgoing_message.sendable?
      mail_message = OutgoingMailer.followup(
        outgoing_message.info_request,
        outgoing_message,
        outgoing_message.incoming_message_followup
      ).deliver_now
      outgoing_message.record_email_delivery(mail_message.to_addrs.join(', '), mail_message.message_id)

      outgoing_message.save!

      # Last event forming the request is now the followup
      kitten_request = InfoRequest.find(@kitten_request.id)
      expect(kitten_request.last_event_forming_initial_request.event_type).to eq('followup_sent')

      travel_to(31.days.from_now) do
        RequestMailer.alert_overdue_requests
        expect(kitten_mails.size).to eq(1)
        ActionMailer::Base.deliveries.clear
      end
    end

    it "sends alerts for embargoed requests" do
      info_request = FactoryBot.create(:embargoed_request)

      travel_to(31.days.from_now) do
        RequestMailer.alert_overdue_requests

        mails = ActionMailer::Base.deliveries.select do |mail|
          mail.body =~ /#{info_request.title}/
        end
        mail = mails[0]
        expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)
      end
    end

    it "does not send alerts for requests with use_notifications set to true" do
      info_request = FactoryBot.create(:use_notifications_request)

      travel_to(31.days.from_now) do
        RequestMailer.alert_overdue_requests

        mails = ActionMailer::Base.deliveries.select do |mail|
          mail.body =~ /#{info_request.title}/
        end
        expect(mails).to be_empty
      end
    end

    context "very overdue alerts" do
      it 'should not create HTML entities in the subject line' do
        info_request = FactoryBot.create(:info_request,
                                         title: "Here's a request")
        mail = RequestMailer.very_overdue_alert(info_request,
                                                info_request.user)
        expect(mail.subject).to eq "You're long overdue a response " \
                                   "to your FOI request - Here's a request"
      end

      context "when the user does not use default locale" do
        before do
          @info_request = FactoryBot.create(:info_request, title: "A request")
          @info_request.user.locale = 'es'
          @mail = RequestMailer.very_overdue_alert(
            @info_request,
            @info_request.user
          )
        end

        it "translates the subject" do
          expect(@mail.subject).to eq(
            "La respuesta a tu solicitud de información está muy retrasada - "\
            "A request"
          )
        end
      end

      it "sends a very overdue alert mail to creators of very overdue requests" do
        travel_to(Time.now + 61.days) do
          RequestMailer.alert_overdue_requests
          expect(kitten_mails.size).to eq(1)
          mail = kitten_mails[0]

          expect(mail.body).to match(/required by law/)
          expect(mail.to_addrs.first.to_s).to eq(@kitten_request.user.email)

          mail.body.to_s =~ /(http:\/\/.*)/
          mail_url = $1

          expect(mail_url).to match(
            new_request_followup_path(
              request_url_title: @kitten_request.url_title
            )
          )
        end
      end

      it "sends very overdue alerts for embargoed requests" do
        info_request = FactoryBot.create(:embargoed_request)

        travel_to(61.days.from_now) do
          RequestMailer.alert_overdue_requests
          mails = ActionMailer::Base.deliveries.select do |mail|
            mail.body =~ /#{info_request.title}/
          end
          mail = mails[0]
          # Check that this is a very overdue email, not just an overdue one
          expect(mail.body).not_to match(/promptly/)
          expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)
        end
      end

      it "does not send alerts for requests with use_notifications set to true" do
        info_request = FactoryBot.create(:use_notifications_request)

        travel_to(61.days.from_now) do
          RequestMailer.alert_overdue_requests

          mails = ActionMailer::Base.deliveries.select do |mail|
            mail.body =~ /#{info_request.title}/
          end
          expect(mails).to be_empty
        end
      end
    end
  end

  describe "not_clarified_alert" do
    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.not_clarified_alert(FactoryBot.create(:info_request, title: "Here's a request"), FactoryBot.create(:incoming_message))
      expect(mail.subject).to eq "Clarify your FOI request - Here's a request"
    end

    context "when the user does not use default locale" do
      before do
        info_request = FactoryBot.create(:info_request, title: "A request")
        info_request.user.locale = 'es'
        @mail = RequestMailer.not_clarified_alert(
          info_request,
          FactoryBot.create(:incoming_message)
        )
      end

      it "translates the subject" do
        expect(@mail.subject).to eq(
          "Clarifica tu solicitud de información - A request"
        )
      end
    end
  end

  describe "comment_on_alert" do
    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.comment_on_alert(FactoryBot.create(:info_request, title: "Here's a request"), FactoryBot.create(:comment))
      expect(mail.subject).to eq "Somebody added a note to your FOI request - Here's a request"
    end

    context "when the user does not use default locale" do
      before do
        info_request = FactoryBot.create(:info_request, title: "A request")
        info_request.user.locale = 'es'
        @mail = RequestMailer.comment_on_alert(
          info_request,
          FactoryBot.create(:comment)
        )
      end

      it "translates the subject" do
        expect(@mail.subject).to eq(
          "Nuevo comentario en tu solicitud de acceso a información - "\
          "A request"
        )
      end
    end
  end

  describe "comment_on_alert_plural" do
    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.comment_on_alert_plural(FactoryBot.create(:info_request, title: "Here's a request"), 2, FactoryBot.create(:comment))
      expect(mail.subject).to eq "Some notes have been added to your FOI request - Here's a request"
    end

    context "when the user does not use default locale" do
      before do
        info_request = FactoryBot.create(:info_request, title: "A request")
        info_request.user.locale = 'es'
        @mail = RequestMailer.comment_on_alert_plural(
          info_request,
          2,
          FactoryBot.create(:comment)
        )
      end

      it "translates the subject" do
        expect(@mail.subject).to eq(
          "Nuevos comentarios en tu solicitud de acceso a información - "\
          "A request"
        )
      end
    end
  end

  describe "clarification required alerts" do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:last_incoming_message) { info_request.incoming_messages.last }

    before do
      info_request.update_column(:updated_at, 5.days.ago)
    end

    context "when request needs clarification" do
      let(:info_request) do
        FactoryBot.create(:info_request, :with_incoming, :waiting_clarification)
      end

      it "should send an alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/asked you to explain/)
        expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)

        mail_url = mail.body.to_s.match(/(http:\/\/.*)/)[0]
        expect(mail_url).to match(
          new_request_incoming_followup_path(
            info_request.url_title,
            incoming_message_id: info_request.incoming_messages.last.id
          )
        )
      end
    end

    context "when request has needed clarification for over 3 months ago" do
      let(:info_request) do
        FactoryBot.create(:info_request, :with_incoming, :waiting_clarification)
      end

      before do
        last_incoming_message.update(created_at: 3.months.ago)
      end

      it "should not send an alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end

    context "when request doesn't have a public last response" do
      let(:info_request) do
        FactoryBot.create(:info_request, :with_incoming, :waiting_clarification)
      end

      before do
        last_incoming_message.update(prominence: 'hidden')
      end

      it "should not send an alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end

    context "when requester is banned" do
      let(:info_request) do
        FactoryBot.create(:info_request, :waiting_clarification,
                          user: FactoryBot.build(:user, :banned))
      end

      it "should not send an alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end

    context "when request is embargoed" do
      let(:info_request) do
        FactoryBot.create(:embargoed_request, :waiting_clarification)
      end

      it "should send alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(1)
        mail = deliveries[0]
        expect(mail.body).to match(/asked you to explain/)
        expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)

        mail_url = mail.body.to_s.match(/(http:\/\/.*)/)[0]
        expect(mail_url).to match(
          new_request_incoming_followup_path(
            info_request.url_title,
            incoming_message_id: info_request.incoming_messages.last.id
          )
        )
      end
    end

    context 'when request has use_notifications enabled' do
      let(:info_request) do
        FactoryBot.create(:use_notifications_request, :waiting_clarification)
      end

      it "should not send an alert" do
        RequestMailer.alert_not_clarified_request

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
      end
    end
  end

  describe "comment alerts" do
    it "should send an alert (once and once only)" do
      # delete fixture comment and make new one, so is in last month (as
      # alerts are only for comments in last month, see
      # RequestMailer.alert_comment_on_request)
      existing_comment = info_requests(:fancy_dog_request).comments[0]
      existing_comment.info_request_events[0].destroy
      existing_comment.destroy
      new_comment = info_requests(:fancy_dog_request).add_comment(
        FactoryBot.build(:comment, body: 'I really love making annotations.')
      )

      # send comment alert
      RequestMailer.alert_comment_on_request
      deliveries = ActionMailer::Base.deliveries
      mail = deliveries[0]
      expect(mail.body).to match(/has annotated your/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1
      expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{new_comment.id}")

      # check if we send again, no more go out
      deliveries.clear
      RequestMailer.alert_comment_on_request
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should not send an alert when you comment on your own request" do
      # delete fixture comment and make new one, so is in last month (as
      # alerts are only for comments in last month, see
      # RequestMailer.alert_comment_on_request)
      existing_comment = info_requests(:fancy_dog_request).comments[0]
      existing_comment.info_request_events[0].destroy
      existing_comment.destroy
      info_request = info_requests(:fancy_dog_request)
      info_request.add_comment(
        FactoryBot.build(
          :comment,
          body: 'I also love making annotations.',
          user: info_request.user
        )
      )

      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it 'should not send an alert for a comment on an external request' do
      external_request = info_requests(:external_request)
      external_request.add_comment(
        FactoryBot.build(:comment, body: "This external request is interesting")
      )
      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should send an alert when there are two new comments" do
      info_request = info_requests(:fancy_dog_request)
      # add two comments - the second one should be ignored, as is by the user who made the request.
      # the new comment here, will cause the one in the fixture to be picked up as a new comment by alert_comment_on_request also.
      info_request.add_comment(
        FactoryBot.build(:comment, body: 'Not as daft as this one')
      )
      info_request.add_comment(
        FactoryBot.build(
          :comment, body: 'Or this one!!!', user: info_request.user
        )
      )

      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/There are 2 new annotations/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1
      expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{comments(:silly_comment).id}")
    end

    it "should send alerts for comments on embargoed requests" do
      info_request = FactoryBot.create(:embargoed_request)
      info_request.add_comment(
        FactoryBot.build(:comment, body: "Test comment on embargoed_request")
      )

      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to_addrs.first.to_s).to eq(info_request.user.email)
    end
  end
end

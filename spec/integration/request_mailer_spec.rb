# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe RequestMailer do

  let(:overdue_date) { Time.zone.now - 30.days }
  let(:very_overdue_date) { Time.zone.now - 60.days }

  before(:each) do
    @tapir_request = FactoryGirl.create(:info_request,
                                 :title => "Do you really own a tapir?")
    @tapir_request.outgoing_messages[0].last_sent_at = overdue_date
    @tapir_request.outgoing_messages[0].save!
  end

  describe "sending overdue request alerts" do

    it "sends an overdue alert mail to request creators" do
      RequestMailer.alert_overdue_requests

      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)
      mail = tapir_mails[0]

      expect(mail.body).to match(/promptly, as normally/)
      expect(mail.to_addrs.first.to_s).to eq(@tapir_request.user.email)

      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      visit mail_url
      expect(current_path).to match(show_response_no_followup_path(@tapir_request.id))
    end

    it "includes clause for schools when sending alerts to request creators" do
      @tapir_request.public_body.tag_string = "school"
      @tapir_request.public_body.save!

      RequestMailer.alert_overdue_requests

      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)
      mail = tapir_mails[0]

      expect(mail.body).to match(/promptly, as normally/)
      expect(mail.to_addrs.first.to_s).to eq(@tapir_request.user.email)
    end

    it "does not send the alert if the user is banned but records it as sent" do
      user = @tapir_request.user
      user.ban_text = 'Banned'
      user.save!
      expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to eq(0)
      RequestMailer.alert_overdue_requests

      deliveries = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(deliveries.size).to eq(0)
      expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to be > 0
    end

    it "sends a very overdue alert mail to creators of very overdue requests" do
      @tapir_request.outgoing_messages[0].last_sent_at = very_overdue_date
      @tapir_request.outgoing_messages[0].save!

      RequestMailer.alert_overdue_requests

      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)
      mail = tapir_mails[0]

      expect(mail.body).to match(/required by law/)
      expect(mail.to_addrs.first.to_s).to eq(@tapir_request.user.email)

      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      visit mail_url
      expect(current_path).to match(show_response_no_followup_path(@tapir_request.id))
    end

    it "does not resend alerts to people who've already received them" do
      RequestMailer.alert_overdue_requests
      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)
      RequestMailer.alert_overdue_requests
      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)
    end

    it "sends alerts for requests where the last event forming the initial
          request is a followup being sent following a request for clarification" do
      RequestMailer.alert_overdue_requests
      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)

      # Request is waiting clarification
      @tapir_request.set_described_state('waiting_clarification')

      # Followup message is sent
      outgoing_message = OutgoingMessage.new(:status => 'ready',
                                             :message_type => 'followup',
                                             :info_request_id => @tapir_request.id,
                                             :body => 'Some text',
                                             :what_doing => 'normal_sort')

      outgoing_message.sendable?
      mail_message = OutgoingMailer.followup(
        outgoing_message.info_request,
        outgoing_message,
        outgoing_message.incoming_message_followup
      ).deliver
      outgoing_message.record_email_delivery(mail_message.to_addrs.join(', '), mail_message.message_id)

      outgoing_message.save!

      tapir_request = InfoRequest.find(@tapir_request.id)

      # Last event forming the request is now the followup
      expect(tapir_request.last_event_forming_initial_request.event_type).to eq('followup_sent')

      # This isn't overdue, so no email
      RequestMailer.alert_overdue_requests
      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(1)

      # Make the followup older
      outgoing_message.last_sent_at = very_overdue_date
      outgoing_message.save!

      # Now it should be alerted on
      RequestMailer.alert_overdue_requests
      tapir_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /tapir/}
      expect(tapir_mails.size).to eq(2)
    end

  end

  describe "sending unclassified new response reminder alerts" do

    before(:each) do
      load_raw_emails_data
    end

    it "sends an alert" do
      RequestMailer.alert_new_response_reminders

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(3) # sufficiently late it sends reminders too
      mail = deliveries[0]
      expect(mail.body).to match(/To let everyone know/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      visit mail_url
      expect(current_path).to match(show_request_path(info_requests(:fancy_dog_request).url_title))
      # TODO: should check anchor tag here :) that it goes to last new response
    end

  end

  describe "clarification required alerts" do

    before(:each) do
      load_raw_emails_data
    end

    it "should send an alert" do
      ir = info_requests(:fancy_dog_request)
      ir.set_described_state('waiting_clarification')
      # this is pretty horrid, but will do :) need to make it waiting
      # clarification more than 3 days ago for the alerts to go out.
      ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.zone.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
      ir.reload

      RequestMailer.alert_not_clarified_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/asked you to explain/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      visit mail_url
      expect(current_path).
        to match(show_response_path(:id => ir.id,
                                    :incoming_message_id => ir.incoming_messages.last.id))
    end

    it "should not send an alert if you are banned" do
      ir = info_requests(:fancy_dog_request)
      ir.set_described_state('waiting_clarification')

      ir.user.ban_text = 'Banned'
      ir.user.save!

      # this is pretty horrid, but will do :) need to make it waiting
      # clarification more than 3 days ago for the alerts to go out.
      ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.zone.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
      ir.reload

      RequestMailer.alert_not_clarified_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

  end

  describe "comment alerts" do
    before(:each) do
      load_raw_emails_data
    end

    it "should send an alert (once and once only)" do
      # delete fixture comment and make new one, so is in last month (as
      # alerts are only for comments in last month, see
      # RequestMailer.alert_comment_on_request)
      existing_comment = info_requests(:fancy_dog_request).comments[0]
      existing_comment.info_request_events[0].destroy
      existing_comment.destroy
      new_comment = info_requests(:fancy_dog_request).add_comment('I really love making annotations.', users(:silly_name_user))

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
      new_comment = info_requests(:fancy_dog_request).add_comment('I also love making annotations.', users(:bob_smith_user))

      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it 'should not send an alert for a comment on an external request' do
      external_request = info_requests(:external_request)
      external_request.add_comment("This external request is interesting", users(:silly_name_user))
      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should send an alert when there are two new comments" do
      # add two comments - the second one sould be ignored, as is by the user who made the request.
      # the new comment here, will cause the one in the fixture to be picked up as a new comment by alert_comment_on_request also.
      new_comment = info_requests(:fancy_dog_request).add_comment('Not as daft as this one', users(:silly_name_user))
      new_comment = info_requests(:fancy_dog_request).add_comment('Or this one!!!', users(:bob_smith_user))

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

  end

end

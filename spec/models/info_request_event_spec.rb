# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_events
#
#  id                  :integer          not null, primary key
#  info_request_id     :integer          not null
#  event_type          :text             not null
#  params_yaml         :text             not null
#  created_at          :datetime         not null
#  described_state     :string
#  calculated_state    :string
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
#  updated_at          :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestEvent do
  describe "when checking for a valid state" do
    it 'should add an error message for described_state if it is not valid' do
      ire = InfoRequestEvent.new(:described_state => 'nope')
      ire.valid?
      expect(ire.errors.messages[:described_state]).to eq ["is not a valid state"]
    end

    it 'should not add an error message for described_state if it is valid' do
      ire = InfoRequestEvent.new(:described_state => 'waiting_response')
      ire.valid?
      expect(ire.errors.messages[:described_state]).to be_blank
    end
  end

  describe "when storing serialized parameters" do
    let(:ire) { InfoRequestEvent.new }

    it "should convert event parameters into YAML and back successfully" do
      example_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
      ire.params = example_params
      expect(ire.params_yaml).to eq(example_params.to_yaml)
      expect(ire.params).to eq(example_params)
    end

    it "should restore UTF8-heavy params stored under ruby 1.8 as UTF-8" do
      utf8_params = "--- \n:foo: !binary |\n  0KLQvtCz0LDRiCDR\n"
      ire.params_yaml = utf8_params
      expect(ire.params[:foo].encoding.to_s).to eq('UTF-8') if ire.params[:foo].respond_to?(:encoding)
    end

    it "should store the incoming_message, outgoing_messsage and comment ids" do
      example_params = {:incoming_message_id => 1,
                        :outgoing_message_id => 2,
                        :comment_id => 3}
      ire.params = example_params
      expect(ire.params).to eq(example_params)
    end

    it "should allow params_yaml to be blank" do
      ire.params_yaml = ''

      expect(ire.params).to eql({})
    end
  end

  describe 'when deciding if it is indexed by search' do

    it 'returns a falsey value for a comment that is not visible' do
      comment = FactoryBot.create(:hidden_comment)
      comment_event = FactoryBot.build(:comment_event, :comment => comment)
      expect(comment_event.indexed_by_search?).to be_falsey
    end

    it 'returns a truthy value for a comment that is visible' do
      comment = FactoryBot.create(:comment)
      comment_event = FactoryBot.build(:comment_event, :comment => comment)
      expect(comment_event.indexed_by_search?).to be_truthy
    end

    it 'returns a falsey value for an incoming message that is not indexed by search' do
      incoming_message = FactoryBot.create(:incoming_message, :hidden)
      response_event = FactoryBot.build(:response_event,
                                        :incoming_message => incoming_message)
      expect(response_event.indexed_by_search?).to be_falsey
    end

    it 'returns a truthy value for an incoming message that is indexed by search' do
      incoming_message = FactoryBot.create(:incoming_message)
      response_event = FactoryBot.build(:response_event,
                                        :incoming_message => incoming_message)
      expect(response_event.indexed_by_search?).to be_truthy
    end

    it 'returns a falsey value for an outgoing message that is not indexed by search' do
      outgoing_message = FactoryBot.create(:hidden_followup)
      followup_event = FactoryBot.build(:followup_sent_event,
                                        :outgoing_message => outgoing_message)
      expect(followup_event.indexed_by_search?).to be_falsey
    end

    it 'returns a truthy value for an outgoing message that is indexed by search' do
      outgoing_message = FactoryBot.create(:new_information_followup)
      followup_event = FactoryBot.build(:followup_sent_event,
                                        :outgoing_message => outgoing_message)
      expect(followup_event.indexed_by_search?).to be_truthy
    end

    it 'returns a falsey value for an overdue event' do
      overdue_event = FactoryBot.build(:overdue_event)
      expect(overdue_event.indexed_by_search?).to be_falsey
    end

    it 'returns a falsey value for a very overdue event' do
      very_overdue_event = FactoryBot.build(:very_overdue_event)
      expect(very_overdue_event.indexed_by_search?).to be_falsey
    end

    it 'returns a falsey value for an embargo expiry event' do
      expire_embargo_event = FactoryBot.build(:expire_embargo_event)
      expect(expire_embargo_event.indexed_by_search?).to be_falsey
    end
  end

  describe '.count_of_hides_by_week' do
    it 'counts hide events by week' do
      FactoryBot.create(:hide_event, created_at: Time.utc(2016, 1, 24))
      FactoryBot.create(:edit_event, created_at: Time.utc(2016, 1, 18))
      FactoryBot.create(:edit_event, created_at: Time.utc(2016, 1, 11))
      FactoryBot.create(:hide_event, created_at: Time.utc(2016, 1, 7))
      FactoryBot.create(:hide_event, created_at: Time.utc(2016, 1, 4))

      expect(InfoRequestEvent.count_of_hides_by_week).to eql(
        [
          [Date.parse("2016-01-04"), 2],
          [Date.parse("2016-01-18"), 1]
        ]
      )
    end
  end

  describe '#described_at' do
    let(:ire) { FactoryBot.create(:info_request_event) }

    it 'should return the created_at date if no description has been added' do
      expect(ire.described_at).to eq(ire.created_at)
    end

    it 'should return the last_described_at date if a description has been added' do
      ire.set_calculated_state!('not_held')
      expect(ire.described_at).to eq(ire.last_described_at)
    end
  end

  describe '#requested_by' do
    it "should return the slug of the associated request's user" do
      ire = FactoryBot.create(:info_request_event)
      expect(ire.requested_by).to eq(ire.info_request.user_name_slug)
    end
  end

  describe '#requested_from' do
    it "should return an array of translated public body url_name values" do
      ire = FactoryBot.create(:info_request_event)
      public_body = ire.info_request.public_body
      expect(ire.requested_from).to eq([public_body.url_name])
    end
  end

  describe '#commented_by' do
    context 'if it is a comment event' do
      it "should return the commenter's url_name" do
        user = FactoryBot.create(:user)
        comment = FactoryBot.create(:comment, :user => user)
        ire = FactoryBot.create(:info_request_event,
                                :event_type => 'comment',
                                :comment => comment)
        expect(ire.commented_by).to eq(user.url_name)
      end
    end

    context 'if it is not a comment event' do
      it 'should return a blank string' do
        ire = FactoryBot.create(:info_request_event)
        expect(ire.commented_by).to eq('')
      end
    end
  end

  describe '#variety' do
    it 'should be an alias for event_type' do
      ire = FactoryBot.create(:info_request_event)
      expect(ire.variety).to eq(ire.event_type)
    end
  end

  describe '#latest_variety' do
    it 'should return the variety for the most recent event of the related request' do
      ire = FactoryBot.create(:info_request_event)
      request = ire.info_request
      new_event = FactoryBot.create(:info_request_event,
                                    :event_type => 'comment',
                                    :info_request => request)
      request.reload
      expect(ire.latest_variety).to eq('comment')
    end
  end

  describe '#latest_status' do
    it 'should return the calculated_state of the most recent event of the related request' do
      ire = FactoryBot.create(:info_request_event)
      request = ire.info_request
      new_event = FactoryBot.create(:info_request_event,
                                    :event_type => 'comment',
                                    :info_request => request)
      new_event.set_calculated_state!('internal_review')
      request.reload
      expect(ire.latest_status).to eq('internal_review')
    end
  end

  describe '#title' do
    context 'a sent event' do
      it 'should return the related info_request title' do
        info_request = FactoryBot.create(:info_request, :title => "Hi!")
        ire = FactoryBot.create(:info_request_event,
                                :info_request => info_request,
                                :event_type => 'sent')

        expect(ire.title).to eq("Hi!")
      end
    end

    context 'not a sent event' do
      it 'should return a blank string' do
        ire = FactoryBot.create(:info_request_event)
        expect(ire.title).to eq('')
      end
    end
  end

  describe '#filetype' do
    context 'a response event' do
      let(:ire) { ire = FactoryBot.create(:response_event) }

      it 'should raise an error if there is not incoming_message' do
        ire.incoming_message = nil
        expect { ire.filetype }.to raise_error.
          with_message(/event type is 'response' but no incoming message for event/)
      end

      it 'should return a blank string if there are no attachments' do
        info_request = ire.info_request
        expect(ire.filetype).to eq('')
      end

      it 'should return a space separated list of the attachment file types' do
        info_request = ire.info_request
        incoming = FactoryBot.create(:incoming_message_with_attachments,
                                     :info_request => info_request)
        ire.incoming_message = incoming
        expect(ire.filetype).to eq('pdf')
      end
    end

    context 'not a response event' do
      it 'should return a blank string' do
        ire = FactoryBot.create(:info_request_event, :event_type => 'comment')
        expect(ire.filetype).to eq('')
      end
    end
  end

  describe '#visible' do
    context 'is a comment' do
      it 'should return the visibility of the comment' do
        comment = FactoryBot.create(:comment, :visible => false)
        ire = FactoryBot.create(:info_request_event,
                                :event_type => 'comment',
                                :comment => comment)
        expect(ire.visible).to eq(false)
      end
    end

    context 'is not a comment' do
      it 'should return true' do
        ire = FactoryBot.create(:info_request_event)
        expect(ire.visible).to eq(true)
      end
    end
  end

  describe '#params_diff' do
    let(:ire) { InfoRequestEvent.new }

    it "should return old, new and other params" do
      ire.params = {:old_foo => 'this is stuff', :foo => 'stuff', :bar => 84}
      expected_hash = {
        :new => {:foo => 'stuff'},
        :old => {:foo => 'this is stuff'},
        :other => {:bar => "84"}}
      expect(ire.params_diff).to eq(expected_hash)
    end

    it 'should drop matching old and new values' do
      ire.params = {:old_foo => 'stuff', :foo => 'stuff', :bar => 84}
      expected_hash = {:new => {}, :old => {}, :other => {:bar => "84"}}
      expect(ire.params_diff).to eq(expected_hash)
    end

    it 'returns a url_name if passed a User' do
      user = FactoryBot.build(:user)
      ire.params = {:old_foo => "", :foo => user}
      expected_hash = {
        :new => {:foo => user.url_name},
        :old => {:foo => ""},
        :other => {}}
      expect(ire.params_diff).to eq(expected_hash)
    end
  end

  describe 'after saving' do
    let(:request) { FactoryBot.create(:info_request) }

    it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
      event = InfoRequestEvent.new(:info_request => request,
                                   :event_type => 'sent',
                                   :params => {})
      expect(event).to receive(:xapian_mark_needs_index)
      event.run_callbacks(:save)
    end

    context "the incoming_message is not hidden" do

      it "updates the parent info_request's last_public_response_at value" do
        im = FactoryBot.create(:incoming_message)
        response_event = FactoryBot.
                          create(:info_request_event, :event_type => 'response',
                                                      :info_request => request,
                                                      :incoming_message => im)
        expect(request.last_public_response_at).to be_within(1.second).
            of response_event.created_at
      end

    end

    context "the event is not a response" do

      it "does not update the info_request's last_public_response_at value" do
        expect_any_instance_of(InfoRequestEvent).not_to receive(:update_request)
        event = FactoryBot.create(:info_request_event, :event_type => 'comment',
                                                       :info_request => request)
        expect(request.last_public_response_at).to be_nil
      end

    end

    context "the incoming_message is hidden" do

      it "sets the parent info_request's last_public_response_at to nil" do
        im = FactoryBot.create(:incoming_message, :prominence => 'hidden')
        response_event = FactoryBot.
                           create(:info_request_event, :event_type => 'response',
                                                       :info_request => request,
                                                       :incoming_message => im)
        expect(request.last_public_response_at).to be_nil
      end

    end

    it "calls the request's create_or_update_request_summary on create" do
      event = FactoryBot.build(:info_request_event)
      expect(event.info_request).to receive(:create_or_update_request_summary)
      event.save
    end

  end

  describe "should know" do
    it "that it's an incoming message" do
      event = InfoRequestEvent.new(:incoming_message => mock_model(IncomingMessage))
      expect(event.is_incoming_message?).to be_truthy
      expect(event.is_outgoing_message?).to be_falsey
      expect(event.is_comment?).to be_falsey
    end

    it "that it's an outgoing message" do
      event = InfoRequestEvent.new(:outgoing_message => mock_model(OutgoingMessage))
      event.id = 1
      expect(event.is_incoming_message?).to be_falsey
      expect(event.is_outgoing_message?).to be_truthy
      expect(event.is_comment?).to be_falsey
    end

    it "that it's a comment" do
      event = InfoRequestEvent.new(:comment => mock_model(Comment))
      event.id = 1
      expect(event.is_incoming_message?).to be_falsey
      expect(event.is_outgoing_message?).to be_falsey
      expect(event.is_comment?).to be_truthy
    end
  end

  describe "doing search/index stuff" do
    before(:each) do
      load_raw_emails_data
      parse_all_incoming_messages
    end

    it 'should get search text for outgoing messages' do
      event = info_request_events(:useless_outgoing_message_event)
      message = outgoing_messages(:useless_outgoing_message).body
      expect(event.search_text_main).to eq(message + "\n\n")
    end

    it 'should get search text for incoming messages' do
      event = info_request_events(:useless_incoming_message_event)
      expect(event.search_text_main.strip).to eq("No way! I'm not going to tell you that in a month of Thursdays.\n\nThe Geraldine Quango")
    end

    it 'should get clipped text for incoming messages, and cache it too' do
      event = info_request_events(:useless_incoming_message_event)

      event.incoming_message_selective_columns("cached_main_body_text_folded").cached_main_body_text_folded = nil
      expect(event.search_text_main(true).strip).to eq("No way! I'm not going to tell you that in a month of Thursdays.\n\nThe Geraldine Quango")
      expect(event.incoming_message_selective_columns("cached_main_body_text_folded").cached_main_body_text_folded).not_to eq(nil)
    end
  end

  describe 'when asked if it has the same email as a previous send' do
    let(:info_request_event) { InfoRequestEvent.new }

    it 'should return true if the email in its params and the previous email the request was sent to are both nil' do
      allow(info_request_event).to receive(:params).and_return({})
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
      expect(info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should return false if one email address exists and the other does not' do
      allow(info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
      expect(info_request_event.same_email_as_previous_send?).to be false
    end

    it 'should return true if the addresses are identical' do
      allow(info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
      expect(info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should return false if the addresses are different' do
      allow(info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('different@example.com')
      expect(info_request_event.same_email_as_previous_send?).to be false
    end

    it 'should return true if the addresses have different formats' do
      allow(info_request_event).to receive(:params).and_return(:email => 'A Test <test@example.com>')
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
      expect(info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should handle non-ascii characters in the name input' do
      address = "\"Someone’s name\" <test@example.com>"
      allow(info_request_event).to receive(:params).and_return(:email => address)
      allow(info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(address)
      expect(info_request_event.same_email_as_previous_send?).to be true
    end
  end

  describe '#set_calculated_state!' do
    let(:info_request_event) { FactoryBot.build(:sent_event) }

    before do
      info_request_event.set_calculated_state!('sent')
      @timestamp = info_request_event.last_described_at
    end

    context 'when the existing state is the same as the new state' do
      it 'does not set the last described at time' do
        info_request_event.set_calculated_state!('sent')
        expect(info_request_event.last_described_at).to eql(@timestamp)
      end
    end

    context 'when the existing state is not the same as the new state' do
      it 'sets the last described at time' do
        info_request_event.set_calculated_state!('response')
        expect(info_request_event.last_described_at).to be > @timestamp
      end

      it 'sets the calculated state' do
        info_request_event.set_calculated_state!('response')
        expect(info_request_event.calculated_state).to eql('response')
      end
    end
  end

  describe '#destroy' do
    let (:info_request) { FactoryBot.create(:info_request)}
    let (:event) { InfoRequestEvent.create(:info_request => info_request,
                                           :event_type => 'sent',
                                           :params => {})
                 }

    it 'should destroy the info_request_event' do
      event.destroy
      expect(InfoRequestEvent.where(:id => event.id)).to be_empty
    end

    it 'should destroy associated user_info_request_sent_alerts' do
      user = FactoryBot.create(:user)
      UserInfoRequestSentAlert.create(:info_request_event_id => event.id,
                                      :alert_type => 'overdue_1',
                                      :user => user,
                                      :info_request => info_request)
      event.destroy
      expect(UserInfoRequestSentAlert.where(:info_request_event_id => event.id)).
        to be_empty
    end

    it 'should destroy associated track_things_sent_emails' do
      track_thing = FactoryBot.create(:search_track,
                                      :info_request => info_request)
      TrackThingsSentEmail.create(:track_thing => track_thing,
                                  :info_request_event => event)
      event.reload
      event.destroy
      expect(TrackThingsSentEmail.where(:info_request_event_id => event.id)).
        to be_empty
    end

  end

  describe "editing requests" do
    let(:unchanged_params) do
      { :editor => "henare",
        :old_title => "How much wood does a woodpecker peck?",
        :title => "How much wood does a woodpecker peck?",
        :old_described_state => "rejected",
        :described_state => "rejected",
        :old_awaiting_description => false,
        :awaiting_description => false,
        :old_allow_new_responses_from => "anybody",
        :allow_new_responses_from => "anybody",
        :old_handle_rejected_responses => "bounce",
        :handle_rejected_responses => "bounce",
        :old_tag_string => "",
        :tag_string => "",
        :old_comments_allowed => true,
        :comments_allowed => true }
    end

    it "should change type to hidden when only editing prominence to hidden" do
      params = unchanged_params.merge({:old_prominence => "normal", :prominence => "hidden"})

      ire = InfoRequestEvent.create!(:info_request => FactoryBot.create(:info_request),
                                     :event_type => "edit",
                                     :params => params)

      expect(ire.event_type).to eql "hide"
    end

    it "should change type to hidden when only editing prominence to requester_only" do
      params = unchanged_params.merge({:old_prominence => "normal", :prominence => "requester_only"})

      ire = InfoRequestEvent.create!(:info_request => FactoryBot.create(:info_request),
                                     :event_type => "edit",
                                     :params => params)

      expect(ire.event_type).to eql "hide"
    end

    it "should change type to hidden when only editing prominence to backpage" do
      params = unchanged_params.merge({:old_prominence => "normal", :prominence => "backpage"})

      ire = InfoRequestEvent.create!(:info_request => FactoryBot.create(:info_request),
                                     :event_type => "edit",
                                     :params => params)

      expect(ire.event_type).to eql "hide"
    end
  end

  describe "#only_editing_prominence_to_hide?" do
    let(:unchanged_params) do
      { :editor => "henare",
        :old_title => "How much wood does a woodpecker peck?",
        :title => "How much wood does a woodpecker peck?",
        :old_described_state => "rejected",
        :described_state => "rejected",
        :old_awaiting_description => false,
        :awaiting_description => false,
        :old_allow_new_responses_from => "anybody",
        :allow_new_responses_from => "anybody",
        :old_handle_rejected_responses => "bounce",
        :handle_rejected_responses => "bounce",
        :old_tag_string => "",
        :tag_string => "",
        :old_comments_allowed => true,
        :comments_allowed => true }
    end

    it "should be false if it's not an edit" do
      ire = InfoRequestEvent.new(:event_type => "resent")

      expect(ire.only_editing_prominence_to_hide?).to be false
    end

    it "should be false if it's already a hide event" do
      ire = InfoRequestEvent.new(:event_type => "hide")

      expect(ire.only_editing_prominence_to_hide?).to be false
    end

    it "should be false if editing multiple conditions" do
      params = unchanged_params.merge({ :old_prominence => "normal",
                                        :prominence => "backpage",
                                        :old_comments_allowed => true,
                                        :comments_allowed => false })

      ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

      expect(ire.only_editing_prominence_to_hide?).to be false
    end

    context "when only editing prominence to hidden" do
      let(:params) { unchanged_params.merge({:old_prominence => "normal", :prominence => "hidden"}) }

      it do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be true
      end
    end

    context "when only editing prominence to requester_only" do
      let(:params) { unchanged_params.merge({:old_prominence => "normal", :prominence => "requester_only"}) }

      it "should be true if only editing prominence to requester_only" do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be true
      end
    end

    context "when only editing prominence to backpage" do
      let(:params) { unchanged_params.merge({:old_prominence => "normal", :prominence => "backpage"}) }

      it "should be true if only editing prominence to backpage" do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be true
      end
    end

    context "when the old prominence was hidden" do
      let(:params) { unchanged_params.merge({:old_prominence => "hidden", :prominence => "requester_only"}) }

      it do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be false
      end
    end

    context "when the old prominence was requester_only" do
      let(:params) { unchanged_params.merge({:old_prominence => "requester_only", :prominence => "hidden"}) }

      it do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be false
      end
    end

    context "when the old prominence was backpage" do
      let(:params) { unchanged_params.merge({:old_prominence => "backpage", :prominence => "hidden"}) }

      it do
        ire = InfoRequestEvent.new(:event_type => "edit", :params => params)

        expect(ire.only_editing_prominence_to_hide?).to be false
      end
    end
  end

  describe '#resets_due_dates?' do

    it 'returns true if the event is a sending of the request' do
      info_request_event = FactoryBot.create(:sent_event)
      expect(info_request_event.resets_due_dates?).to be true
    end

    it 'returns true if the event is a clarification' do
      info_request = FactoryBot.create(:info_request)
      info_request.set_described_state('waiting_clarification')
      event = info_request.log_event('followup_sent', {})
      expect(event.resets_due_dates?).to be true
    end

    it 'returns false if the event is neither a sending of the request or a
        clarification' do
      info_request_event = FactoryBot.create(:response_event)
      expect(info_request_event.resets_due_dates?).to be false
    end
  end


  describe '#is_request_sending?' do

    it 'returns true if the event type is "sent"' do
      info_request_event = FactoryBot.create(:sent_event)
      expect(info_request_event.is_request_sending?).to be true
    end

    it 'returns true if the event type is "resent"' do
      info_request_event = FactoryBot.create(:resent_event)
      expect(info_request_event.is_request_sending?).to be true
    end

    it 'returns false if the event type is not "sent" or "resent"' do
      info_request_event = FactoryBot.create(:response_event)
      expect(info_request_event.is_request_sending?).to be false
    end
  end


  describe '#is_clarification?' do

    it 'should return false if there has been no request for clarification' do
      info_request = FactoryBot.create(:info_request_with_incoming)
      event = info_request.log_event('followup_sent', {})
      expect(event.is_clarification?).to be false
    end

    it 'should return true if the event is the first followup after a request
        for clarification' do
      info_request = FactoryBot.create(:info_request_with_incoming)
      info_request.set_described_state('waiting_clarification')
      event = info_request.log_event('followup_sent', {})
      expect(event.is_clarification?).to be true
    end

    it 'should return false if there was a request for clarification but there
        has since been a followup' do
      info_request = FactoryBot.create(:info_request_with_incoming)
      info_request.set_described_state('waiting_clarification')
      info_request.log_event('followup_sent', {})
      event = info_request.log_event('followup_sent', {})
      expect(event.is_clarification?).to be false
    end

    it 'should return false if there was a request for clarification after
        this event' do
      info_request = FactoryBot.create(:info_request_with_incoming)
      event = info_request.log_event('followup_sent', {})
      info_request.set_described_state('waiting_clarification')
      expect(event.is_clarification?).to be false
    end
  end

  describe 'notifications' do
    it 'deletes associated notifications when destroyed' do
      notification = FactoryBot.create(:notification)
      info_request_event = notification.info_request_event
      expect(Notification.where(id: notification.id)).to exist
      info_request_event.destroy
      expect(Notification.where(id: notification.id)).not_to exist
    end
  end

  describe '#recheck_due_dates' do

    context 'if the event is a response that is then labelled as
             a clarification request' do
      let(:response_event) do
        response = nil
        time_travel_to(1.month.ago) do
          response = FactoryBot.create(:response_event)
        end
        response.described_state = 'waiting_clarification'
        response.calculated_state = 'waiting_clarification'
        response.save!
        response
      end

      context 'if there is a subsequent followup' do
        let!(:followup) do
          FactoryBot.create(:followup_sent_event,
                            :info_request => response_event.info_request)
        end

        it 'resets the due dates on the request' do
          info_request = response_event.info_request
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(1.month.ago.to_date)
          response_event.recheck_due_dates
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(Time.zone.now.to_date)
        end

      end

      context 'if there is no subsequent followup' do

        it 'does not reset the due dates on the request' do
          info_request = response_event.info_request
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(1.month.ago.to_date)
          response_event.recheck_due_dates
          expect(info_request.reload.date_initial_request_last_sent_at).
            to eq(1.month.ago.to_date)
        end

      end

    end

  end

end

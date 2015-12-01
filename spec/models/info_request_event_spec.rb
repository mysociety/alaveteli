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
#  described_state     :string(255)
#  calculated_state    :string(255)
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
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
      expect(ire.errors.messages[:described_state]).to be_nil
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
  end

  describe 'when deciding if it is indexed by search' do
    let(:comment) { mock_model(Comment) }
    let(:incoming_message) { mock_model(IncomingMessage) }
    let(:outgoing_message) { mock_model(OutgoingMessage) }
    let(:info_request) { mock_model(InfoRequest, :indexed_by_search? => true) }

    it 'should return a falsey value for a comment that is not visible' do
      allow(comment).to receive(:visible).and_return(false)
      info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                :comment => comment,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for a comment that is visible' do
      allow(comment).to receive(:visible).and_return(true)
      info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                :comment => comment,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_truthy
    end

    it 'should return a truthy value for an incoming message that is not indexed by search' do
      allow(incoming_message).to receive(:indexed_by_search?).and_return false
      info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                :incoming_message => incoming_message,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for an incoming message that is indexed by search' do
      allow(incoming_message).to receive(:indexed_by_search?).and_return true
      info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                :incoming_message => incoming_message,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_truthy
    end

    it 'should return a falsey value for an outgoing message that is not indexed by search' do
      allow(outgoing_message).to receive(:indexed_by_search?).and_return false
      info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                :outgoing_message => outgoing_message,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for an outgoing message that is indexed by search' do
      allow(outgoing_message).to receive(:indexed_by_search?).and_return true
      info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                :outgoing_message => outgoing_message,
                                                :info_request => info_request)
      expect(info_request_event.indexed_by_search?).to be_truthy
    end
  end

  describe '#described_at' do
    let(:ire) { FactoryGirl.create(:info_request_event) }

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
      ire = FactoryGirl.create(:info_request_event)
      expect(ire.requested_by).to eq(ire.info_request.user_name_slug)
    end
  end

  describe '#requested_from' do
    it "should return an array of translated public body url_name values" do
      ire = FactoryGirl.create(:info_request_event)
      public_body = ire.info_request.public_body
      expect(ire.requested_from).to eq([public_body.url_name])
    end
  end

  describe '#commented_by' do
    context 'if it is a comment event' do
      it "should return the commenter's url_name" do
        user = FactoryGirl.create(:user)
        comment = FactoryGirl.create(:comment, :user => user)
        ire = FactoryGirl.create(:info_request_event,
                                 :event_type => 'comment',
                                 :comment => comment)
        expect(ire.commented_by).to eq(user.url_name)
      end
    end

    context 'if it is not a comment event' do
      it 'should return a blank string' do
        ire = FactoryGirl.create(:info_request_event)
        expect(ire.commented_by).to eq('')
      end
    end
  end

  describe '#variety' do
    it 'should be an alias for event_type' do
      ire = FactoryGirl.create(:info_request_event)
      expect(ire.variety).to eq(ire.event_type)
    end
  end

  describe '#latest_variety' do
    it 'should return the variety for the most recent event of the related request' do
      ire = FactoryGirl.create(:info_request_event)
      request = ire.info_request
      new_event = FactoryGirl.create(:info_request_event,
                                     :event_type => 'comment',
                                     :info_request => request)
      request.reload
      expect(ire.latest_variety).to eq('comment')
    end
  end

  describe '#latest_status' do
    it 'should return the calculated_state of the most recent event of the related request' do
      ire = FactoryGirl.create(:info_request_event)
      request = ire.info_request
      new_event = FactoryGirl.create(:info_request_event,
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
        info_request = FactoryGirl.create(:info_request, :title => "Hi!")
        ire = FactoryGirl.create(:info_request_event,
                                 :info_request => info_request,
                                 :event_type => 'sent')

        expect(ire.title).to eq("Hi!")
      end
    end

    context 'not a sent event' do
      it 'should return a blank string' do
        ire = FactoryGirl.create(:info_request_event)
        expect(ire.title).to eq('')
      end
    end
  end

  describe '#filetype' do
    context 'a response event' do
      let(:ire) { ire = FactoryGirl.create(:info_request_event) }

      it 'should raise an error if there is not incoming_message' do
        expect { ire.filetype }.to raise_error.
          with_message(/event type is 'response' but no incoming message for event/)
      end

      it 'should return a blank string if there are no attachments' do
        info_request = ire.info_request
        incoming = FactoryGirl.create(:plain_incoming_message,
                                      :info_request => info_request)
        ire.incoming_message = incoming
        expect(ire.filetype).to eq('')
      end

      it 'should return a space separated list of the attachment file types' do
        info_request = ire.info_request
        incoming = FactoryGirl.create(:incoming_message_with_attachments,
                                      :info_request => info_request)
        ire.incoming_message = incoming
        expect(ire.filetype).to eq('pdf')
      end
    end

    context 'not a response event' do
      it 'should return a blank string' do
        ire = FactoryGirl.create(:info_request_event, :event_type => 'comment')
        expect(ire.filetype).to eq('')
      end
    end
  end

  describe '#visible' do
    context 'is a comment' do
      it 'should return the visibility of the comment' do
        comment = FactoryGirl.create(:comment, :visible => false)
        ire = FactoryGirl.create(:info_request_event,
                                 :event_type => 'comment',
                                 :comment => comment)
        expect(ire.visible).to eq(false)
      end
    end

    context 'is not a comment' do
      it 'should return true' do
        ire = FactoryGirl.create(:info_request_event)
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
  end

  describe 'after saving' do
    let(:request) { FactoryGirl.create(:info_request) }

    it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
      event = InfoRequestEvent.new(:info_request => request,
                                   :event_type => 'sent',
                                   :params => {})
      expect(event).to receive(:xapian_mark_needs_index)
      event.run_callbacks(:save)
    end

    context "the incoming_message is not hidden" do

      it "updates the parent info_request's last_public_response_at value" do
        im = FactoryGirl.create(:incoming_message)
        response_event = FactoryGirl.
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
        event = FactoryGirl.create(:info_request_event, :event_type => 'comment',
                                                        :info_request => request)
        expect(request.last_public_response_at).to be_nil
      end

    end

    context "the incoming_message is hidden" do

      it "sets the parent info_request's last_public_response_at to nil" do
        im = FactoryGirl.create(:incoming_message, :prominence => 'hidden')
        response_event = FactoryGirl.
                          create(:info_request_event, :event_type => 'response',
                                                      :info_request => request,
                                                      :incoming_message => im)
        expect(request.last_public_response_at).to be_nil
      end

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
    let(:info_request_event) { FactoryGirl.build(:sent_event) }

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
    let (:info_request) { FactoryGirl.create(:info_request)}
    let (:event) { InfoRequestEvent.create(:info_request => info_request,
                                           :event_type => 'sent',
                                           :params => {})
                 }

    it 'should destroy the info_request_event' do
      event.destroy
      expect(InfoRequestEvent.where(:id => event.id)).to be_empty
    end

    it 'should destroy associated user_info_request_sent_alerts' do
      user = FactoryGirl.create(:user)
      UserInfoRequestSentAlert.create(:info_request_event_id => event.id,
                                      :alert_type => 'overdue_1',
                                      :user => user,
                                      :info_request => info_request)
      event.destroy
      expect(UserInfoRequestSentAlert.where(:info_request_event_id => event.id)).
        to be_empty
    end

    it 'should destroy associated track_things_sent_emails' do
      track_thing = FactoryGirl.create(:search_track,
                                       :info_request => info_request)
      TrackThingsSentEmail.create(:track_thing => track_thing,
                                  :info_request_event => event)
      event.reload
      event.destroy
      expect(TrackThingsSentEmail.where(:info_request_event_id => event.id)).
        to be_empty
    end

  end
end

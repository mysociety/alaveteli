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

  describe "when storing serialized parameters" do

    it "should convert event parameters into YAML and back successfully" do
      ire = InfoRequestEvent.new
      example_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
      ire.params = example_params
      expect(ire.params_yaml).to eq(example_params.to_yaml)
      expect(ire.params).to eq(example_params)
    end

    it "should restore UTF8-heavy params stored under ruby 1.8 as UTF-8" do
      ire = InfoRequestEvent.new
      utf8_params = "--- \n:foo: !binary |\n  0KLQvtCz0LDRiCDR\n"
      ire.params_yaml = utf8_params
      expect(ire.params[:foo].encoding.to_s).to eq('UTF-8') if ire.params[:foo].respond_to?(:encoding)
    end
  end

  describe 'when deciding if it is indexed by search' do

    before do
      @comment = mock_model(Comment)
      @incoming_message = mock_model(IncomingMessage)
      @outgoing_message = mock_model(OutgoingMessage)
      @info_request = mock_model(InfoRequest, :indexed_by_search? => true)
    end

    it 'should return a falsey value for a comment that is not visible' do
      allow(@comment).to receive(:visible).and_return(false)
      @info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                 :comment => @comment,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for a comment that is visible' do
      allow(@comment).to receive(:visible).and_return(true)
      @info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                 :comment => @comment,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_truthy
    end

    it 'should return a truthy value for an incoming message that is not indexed by search' do
      allow(@incoming_message).to receive(:indexed_by_search?).and_return false
      @info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                 :incoming_message => @incoming_message,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for an incoming message that is indexed by search' do
      allow(@incoming_message).to receive(:indexed_by_search?).and_return true
      @info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                 :incoming_message => @incoming_message,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_truthy
    end

    it 'should return a falsey value for an outgoing message that is not indexed by search' do
      allow(@outgoing_message).to receive(:indexed_by_search?).and_return false
      @info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                 :outgoing_message => @outgoing_message,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_falsey
    end

    it 'should return a truthy value for an outgoing message that is indexed by search' do
      allow(@outgoing_message).to receive(:indexed_by_search?).and_return true
      @info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                 :outgoing_message => @outgoing_message,
                                                 :info_request => @info_request)
      expect(@info_request_event.indexed_by_search?).to be_truthy
    end
  end

  describe 'after saving' do

    it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
      event = InfoRequestEvent.new(:info_request => mock_model(InfoRequest),
                                   :event_type => 'sent',
                                   :params => {})
      expect(event).to receive(:xapian_mark_needs_index)
      event.run_callbacks(:save)
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

    before do
      @info_request_event = InfoRequestEvent.new
    end

    it 'should return true if the email in its params and the previous email the request was sent to are both nil' do
      allow(@info_request_event).to receive(:params).and_return({})
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
      expect(@info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should return false if one email address exists and the other does not' do
      allow(@info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
      expect(@info_request_event.same_email_as_previous_send?).to be false
    end

    it 'should return true if the addresses are identical' do
      allow(@info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
      expect(@info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should return false if the addresses are different' do
      allow(@info_request_event).to receive(:params).and_return(:email => 'test@example.com')
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('different@example.com')
      expect(@info_request_event.same_email_as_previous_send?).to be false
    end

    it 'should return true if the addresses have different formats' do
      allow(@info_request_event).to receive(:params).and_return(:email => 'A Test <test@example.com>')
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
      expect(@info_request_event.same_email_as_previous_send?).to be true
    end

    it 'should handle non-ascii characters in the name input' do
      address = "\"Someone’s name\" <test@example.com>"
      allow(@info_request_event).to receive(:params).and_return(:email => address)
      allow(@info_request_event).to receive_message_chain(:info_request, :get_previous_email_sent_to).and_return(address)
      expect(@info_request_event.same_email_as_previous_send?).to be true
    end

  end

  describe '#set_calculated_state!' do

    before do
      @info_request_event = FactoryGirl.build(:sent_event)
      @info_request_event.set_calculated_state!('sent')
      @timestamp = @info_request_event.last_described_at
    end

    context 'when the existing state is the same as the new state' do

      it 'does not set the last described at time' do
        @info_request_event.set_calculated_state!('sent')
        expect(@info_request_event.last_described_at).to eql(@timestamp)
      end

    end

    context 'when the existing state is not the same as the new state' do

      it 'sets the last described at time' do
        @info_request_event.set_calculated_state!('response')
        expect(@info_request_event.last_described_at).to be > @timestamp
      end

      it 'sets the calculated state' do
        @info_request_event.set_calculated_state!('response')
        expect(@info_request_event.calculated_state).to eql('response')
      end

    end


  end


end

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
            ire.params_yaml.should == example_params.to_yaml
            ire.params.should == example_params
        end

        it "should restore UTF8-heavy params stored under ruby 1.8 as UTF-8" do
            ire = InfoRequestEvent.new
            utf8_params = "--- \n:foo: !binary |\n  0KLQvtCz0LDRiCDR\n"
            ire.params_yaml = utf8_params
            ire.params[:foo].encoding.to_s.should == 'UTF-8' if ire.params[:foo].respond_to?(:encoding)
        end
    end

    describe 'when deciding if it is indexed by search' do

        before do
            @comment = mock_model(Comment)
            @incoming_message = mock_model(IncomingMessage)
            @outgoing_message = mock_model(OutgoingMessage)
            @info_request = mock_model(InfoRequest, :indexed_by_search? => true)
        end

        it 'should return false for a comment that is not visible' do
            @comment.stub!(:visible).and_return(false)
            @info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                       :comment => @comment,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_false
        end

        it 'should return true for a comment that is visible' do
            @comment.stub!(:visible).and_return(true)
            @info_request_event = InfoRequestEvent.new(:event_type => 'comment',
                                                       :comment => @comment,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_true
        end

        it 'should return false for an incoming message that is not indexed by search' do
            @incoming_message.stub!(:indexed_by_search?).and_return false
            @info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                       :incoming_message => @incoming_message,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_false
        end

        it 'should return true for an incoming message that is indexed by search' do
            @incoming_message.stub!(:indexed_by_search?).and_return true
            @info_request_event = InfoRequestEvent.new(:event_type => 'response',
                                                       :incoming_message => @incoming_message,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_true
        end

        it 'should return false for an outgoing message that is not indexed by search' do
            @outgoing_message.stub!(:indexed_by_search?).and_return false
            @info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                       :outgoing_message => @outgoing_message,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_false
        end

        it 'should return true for an outgoing message that is indexed by search' do
            @outgoing_message.stub!(:indexed_by_search?).and_return true
            @info_request_event = InfoRequestEvent.new(:event_type => 'followup_sent',
                                                       :outgoing_message => @outgoing_message,
                                                       :info_request => @info_request)
            @info_request_event.indexed_by_search?.should be_true
        end
    end

    describe 'after saving' do

        it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
            event = InfoRequestEvent.new(:info_request => mock_model(InfoRequest),
                                         :event_type => 'sent',
                                         :params => {})
            event.should_receive(:xapian_mark_needs_index)
            event.run_callbacks(:save)
        end

    end

    describe "should know" do

        it "that it's an incoming message" do
            event = InfoRequestEvent.new(:incoming_message => mock_model(IncomingMessage))
            event.is_incoming_message?.should be_true
            event.is_outgoing_message?.should be_false
            event.is_comment?.should be_false
        end

        it "that it's an outgoing message" do
            event = InfoRequestEvent.new(:outgoing_message => mock_model(OutgoingMessage))
            event.id = 1
            event.is_incoming_message?.should be_false
            event.is_outgoing_message?.should be_true
            event.is_comment?.should be_false
        end

        it "that it's a comment" do
            event = InfoRequestEvent.new(:comment => mock_model(Comment))
            event.id = 1
            event.is_incoming_message?.should be_false
            event.is_outgoing_message?.should be_false
            event.is_comment?.should be_true
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
            event.search_text_main.should == message + "\n\n"
        end

        it 'should get search text for incoming messages' do
            event = info_request_events(:useless_incoming_message_event)
            event.search_text_main.strip.should == "No way! I'm not going to tell you that in a month of Thursdays.\n\nThe Geraldine Quango"
        end

        it 'should get clipped text for incoming messages, and cache it too' do
            event = info_request_events(:useless_incoming_message_event)

            event.incoming_message_selective_columns("cached_main_body_text_folded").cached_main_body_text_folded = nil
            event.search_text_main(true).strip.should == "No way! I'm not going to tell you that in a month of Thursdays.\n\nThe Geraldine Quango"
            event.incoming_message_selective_columns("cached_main_body_text_folded").cached_main_body_text_folded.should_not == nil
        end

    end

    describe 'when asked if it has the same email as a previous send' do

        before do
            @info_request_event = InfoRequestEvent.new
        end

        it 'should return true if the email in its params and the previous email the request was sent to are both nil' do
            @info_request_event.stub!(:params).and_return({})
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
            @info_request_event.same_email_as_previous_send?.should be_true
        end

        it 'should return false if one email address exists and the other does not' do
            @info_request_event.stub!(:params).and_return(:email => 'test@example.com')
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return(nil)
            @info_request_event.same_email_as_previous_send?.should be_false
        end

        it 'should return true if the addresses are identical' do
            @info_request_event.stub!(:params).and_return(:email => 'test@example.com')
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
            @info_request_event.same_email_as_previous_send?.should be_true
        end

        it 'should return false if the addresses are different' do
            @info_request_event.stub!(:params).and_return(:email => 'test@example.com')
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return('different@example.com')
            @info_request_event.same_email_as_previous_send?.should be_false
        end

        it 'should return true if the addresses have different formats' do
            @info_request_event.stub!(:params).and_return(:email => 'A Test <test@example.com>')
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return('test@example.com')
            @info_request_event.same_email_as_previous_send?.should be_true
        end

        it 'should handle non-ascii characters in the name input' do
            address = "\"Someone’s name\" <test@example.com>"
            @info_request_event.stub!(:params).and_return(:email => address)
            @info_request_event.stub_chain(:info_request, :get_previous_email_sent_to).and_return(address)
            @info_request_event.same_email_as_previous_send?.should be_true
        end

    end

end


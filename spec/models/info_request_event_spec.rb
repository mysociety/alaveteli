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

    end

    describe 'after saving' do

        it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
            event = InfoRequestEvent.new(:info_request => mock_model(InfoRequest),
                                         :event_type => 'sent',
                                         :params => {})
            event.should_receive(:xapian_mark_needs_index)
            event.run_callbacks(:after_save)
        end

    end

    describe "should know" do

        it "that it's an incoming message" do
            event = InfoRequestEvent.new()
            event.stub!(:incoming_message_selective_columns).and_return(1)
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



end


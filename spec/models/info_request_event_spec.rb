require File.dirname(__FILE__) + '/../spec_helper'

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

    describe 'when saving' do 
  
        it 'should mark the model for reindexing in xapian if there is no no_xapian_reindex flag on the object' do
            event = InfoRequestEvent.new(:info_request => mock_model(InfoRequest), 
                                         :event_type => 'sent', 
                                         :params => {}) 
            event.should_receive(:xapian_mark_needs_index)
            event.save!
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
            event.is_incoming_message?.should be_false
            event.is_outgoing_message?.should be_true
            event.is_comment?.should be_false
        end
        
        it "that it's a comment" do
            event = InfoRequestEvent.new(:comment => mock_model(Comment))
            event.is_incoming_message?.should be_false
            event.is_outgoing_message?.should be_false
            event.is_comment?.should be_true
        end

    end
end


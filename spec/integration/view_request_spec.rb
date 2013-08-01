require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When viewing requests" do

    before(:each) do
        load_raw_emails_data
    end

    it "should not make endlessly recursive JSON <link>s" do
        unregistered = without_login
        unregistered.browses_request('why_do_you_have_such_a_fancy_dog?unfold=1')
        unregistered.response.body.should_not include("dog?unfold=1.json")
        unregistered.response.body.should include("dog.json?unfold=1")
    end

    it 'should not raise a routing error when making a json link for a request with an
       "action" querystring param' do
       unregistered = without_login
       unregistered.browses_request('why_do_you_have_such_a_fancy_dog?action=add')
    end

    context 'when a response is hidden' do

        before do
            useless_message = incoming_messages(:useless_incoming_message)
            useless_message.prominence = 'hidden'
            useless_message.save!
        end

        it 'should show a hidden notice to an unregistered user' do
            unregistered = without_login
            response = unregistered.browses_request('why_do_you_have_such_a_fancy_dog')
            response.body.should include("This message has been hidden.")
        end

    end
end


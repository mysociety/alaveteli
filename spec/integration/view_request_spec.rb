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

    context 'when a response has prominence "normal"' do

        before do
            useless_message = incoming_messages(:useless_incoming_message)
            useless_message.prominence = 'normal'
            useless_message.save!
        end

        it 'should show the message itself to any user' do

            # unregistered
            unregistered = without_login
            unregistered.browses_request('why_do_you_have_such_a_fancy_dog')
            unregistered.response.body.should include("No way!")
            unregistered.response.body.should_not include("This message has been hidden.")
            unregistered.response.body.should_not include("sign in</a> to view the message.")

            # requester
            bob = login(:bob_smith_user)
            bob.browses_request('why_do_you_have_such_a_fancy_dog')
            bob.response.body.should include("No way!")
            bob.response.body.should_not include("This message has been hidden.")

            # admin
            confirm(:admin_user)
            admin_user = login(:admin_user)
            admin_user.browses_request('why_do_you_have_such_a_fancy_dog')
            admin_user.response.body.should include('No way!')
            admin_user.response.body.should_not include("This message has prominence \'hidden\'.")

        end

    end

    context 'when a response has prominence "hidden"' do

        before do
            useless_message = incoming_messages(:useless_incoming_message)
            useless_message.prominence = 'hidden'
            useless_message.save!
        end

        it 'should show a hidden notice, not the message, to an unregistered user or the requester and
            the message itself to an admin ' do

            # unregistered
            unregistered = without_login
            unregistered.browses_request('why_do_you_have_such_a_fancy_dog')
            unregistered.response.body.should include("This message has been hidden.")
            unregistered.response.body.should_not include("sign in</a> to view the message.")
            unregistered.response.body.should_not include("No way!")

            # requester
            bob = login(:bob_smith_user)
            bob.browses_request('why_do_you_have_such_a_fancy_dog')
            bob.response.body.should include("This message has been hidden.")
            bob.response.body.should_not include("No way!")

            # admin
            confirm(:admin_user)
            admin_user = login(:admin_user)
            admin_user.browses_request('why_do_you_have_such_a_fancy_dog')
            admin_user.response.body.should include('No way!')
            admin_user.response.body.should include("This message has prominence \'hidden\'. You can only see it because you are logged in as a super user.")

        end

    end

    context 'when as response has prominence "requester_only"' do

        before do
            useless_message = incoming_messages(:useless_incoming_message)
            useless_message.prominence = 'requester_only'
            useless_message.save!
        end

        it 'should show a hidden notice with login link to an unregistered user, and the message itself
            with a hidden note to the requester or an admin' do

            # unregistered
            unregistered = without_login
            unregistered.browses_request('why_do_you_have_such_a_fancy_dog')
            unregistered.response.body.should include("This message has been hidden.")
            unregistered.response.body.should include("sign in</a> to view the message.")
            unregistered.response.body.should_not include("No way!")

            # requester
            bob = login(:bob_smith_user)
            bob.browses_request('why_do_you_have_such_a_fancy_dog')
            bob.response.body.should include("No way!")
            bob.response.body.should include("This message is hidden, so that only you, the requester, can see it.")

            # admin
            confirm(:admin_user)
            admin_user = login(:admin_user)
            admin_user.browses_request('why_do_you_have_such_a_fancy_dog')
            admin_user.response.body.should include('No way!')
            admin_user.response.body.should_not include("This message has been hidden.")
            admin_user.response.body.should include("This message is hidden, so that only you, the requester, can see it.")
        end

    end

end


# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe "When viewing requests" do

  before do
    @info_request = FactoryGirl.create(:info_request)
    @unregistered = without_login
  end

  it "should not make endlessly recursive JSON <link>s" do
    @unregistered.browses_request("#{@info_request.url_title}?unfold=1")
    @unregistered.response.body.should_not include("#{@info_request.url_title}?unfold=1.json")
    @unregistered.response.body.should include("#{@info_request.url_title}.json?unfold=1")
  end

  it 'should not raise a routing error when making a json link for a request with an
       "action" querystring param' do
    @unregistered.browses_request("#{@info_request.url_title}?action=add")
  end

  context "when a request is hidden by an admin" do

    it 'should not retain any cached attachments to be served up by the webserver' do
      admin = login(FactoryGirl.create(:admin_user))
      non_owner = login(FactoryGirl.create(:user))
      info_request = FactoryGirl.create(:info_request_with_incoming_attachments)
      incoming_message = info_request.incoming_messages.first
      attachment_url = "/es/request/#{info_request.id}/response/#{incoming_message.id}/attach/2/interesting.pdf"
      non_owner.get(attachment_url)
      cache_directories_exist?(info_request).should be_true

      # Admin makes the incoming message requester only
      post_data = {:incoming_message => {:prominence => 'hidden',
                                         :prominence_reason => 'boring'}}
      admin.put_via_redirect "/admin/incoming_messages/#{info_request.incoming_messages.first.id}", post_data
      admin.response.should be_success

      cache_directories_exist?(info_request).should be_false
    end

  end

  context 'when a response has prominence "normal"' do

    before do
      @info_request = FactoryGirl.create(:info_request_with_incoming)
    end

    it 'should show the message itself to any user' do

      # unregistered
      unregistered = without_login
      unregistered.browses_request(@info_request.url_title)
      unregistered.response.body.should include("hereisthetext")
      unregistered.response.body.should_not include("This message has been hidden.")
      unregistered.response.body.should_not include("sign in</a> to view the message.")

      # requester
      owner = login(@info_request.user)
      owner.browses_request(@info_request.url_title)
      owner.response.body.should include("hereisthetext")
      owner.response.body.should_not include("This message has been hidden.")

      # admin
      admin_user = login(FactoryGirl.create(:admin_user))
      admin_user.browses_request(@info_request.url_title)
      admin_user.response.body.should include("hereisthetext")
      admin_user.response.body.should_not include("This message has prominence \'hidden\'.")

    end

  end

  context 'when a response has prominence "hidden"' do

    before do
      @info_request = FactoryGirl.create(:info_request_with_incoming)
      message = @info_request.incoming_messages.first
      message.prominence = 'hidden'
      message.prominence_reason = 'It is too irritating.'
      message.save!
    end

    it 'should show a hidden notice, not the message, to an unregistered user or the requester and
            the message itself to an admin ' do

      # unregistered
      unregistered = without_login
      unregistered.browses_request(@info_request.url_title)
      unregistered.response.body.should include("This message has been hidden.")
      unregistered.response.body.should include("It is too irritating.")
      unregistered.response.body.should_not include("sign in</a> to view the message.")
      unregistered.response.body.should_not include("hereisthetext")

      # requester
      owner = login(@info_request.user)
      owner.browses_request(@info_request.url_title)
      owner.response.body.should include("This message has been hidden.")
      owner.response.body.should include("It is too irritating")
      owner.response.body.should_not include("hereisthetext")

      # admin
      admin_user = login(FactoryGirl.create(:admin_user))
      admin_user.browses_request(@info_request.url_title)
      admin_user.response.body.should include('hereisthetext')
      admin_user.response.body.should include("This message has prominence \'hidden\'.")
      admin_user.response.body.should include("It is too irritating.")
      admin_user.response.body.should include("You can only see it because you are logged in as a super user.")

    end

  end

  context 'when a response has prominence "requester_only"' do

    before do
      @info_request = FactoryGirl.create(:info_request_with_incoming)
      message = @info_request.incoming_messages.first
      message.prominence = 'requester_only'
      message.prominence_reason = 'It is too irritating.'
      message.save!
    end

    it 'should show a hidden notice with login link to an unregistered user, and the message itself
            with a hidden note to the requester or an admin' do

      # unregistered
      unregistered = without_login
      unregistered.browses_request(@info_request.url_title)
      unregistered.response.body.should include("This message has been hidden.")
      unregistered.response.body.should include("It is too irritating")
      unregistered.response.body.should include("sign in</a> to view the message.")
      unregistered.response.body.should_not include("hereisthetext")

      # requester
      owner = login(@info_request.user)
      owner.browses_request(@info_request.url_title)
      owner.response.body.should include("hereisthetext")
      owner.response.body.should include("This message is hidden, so that only you, the requester, can see it.")
      owner.response.body.should include("It is too irritating.")

      # admin
      admin_user = login(FactoryGirl.create(:admin_user))
      admin_user.browses_request(@info_request.url_title)
      admin_user.response.body.should include('hereisthetext')
      admin_user.response.body.should_not include("This message has been hidden.")
      admin_user.response.body.should include("This message is hidden, so that only you, the requester, can see it.")
    end

  end

  context 'when an outgoing message has prominence "requester_only"' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      message = @info_request.outgoing_messages.first
      message.prominence = 'requester_only'
      message.prominence_reason = 'It is too irritating.'
      message.save!
    end

    it 'should show a hidden notice with login link to an unregistered user, and the message itself
            with a hidden note to the requester or an admin' do

      # unregistered
      unregistered = without_login
      unregistered.browses_request(@info_request.url_title)
      unregistered.response.body.should include("This message has been hidden.")
      unregistered.response.body.should include("It is too irritating")
      unregistered.response.body.should include("sign in</a> to view the message.")
      unregistered.response.body.should_not include("Some information please")

      # requester
      owner = login(@info_request.user)
      owner.browses_request(@info_request.url_title)
      owner.response.body.should include("Some information please")
      owner.response.body.should include("This message is hidden, so that only you, the requester, can see it.")
      owner.response.body.should include("It is too irritating.")

      # admin
      admin_user = login(FactoryGirl.create(:admin_user))
      admin_user.browses_request(@info_request.url_title)
      admin_user.response.body.should include('Some information please')
      admin_user.response.body.should_not include("This message has been hidden.")
      admin_user.response.body.should include("This message is hidden, so that only you, the requester, can see it.")
    end

  end

end

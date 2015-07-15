# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminOutgoingMessageController do

  describe 'when editing an outgoing message' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      @outgoing = @info_request.outgoing_messages.first
    end

    it 'should be successful' do
      get :edit, :id => @outgoing.id
      response.should be_success
    end

    it 'should assign the incoming message to the view' do
      get :edit, :id => @outgoing.id
      assigns[:outgoing_message].should == @outgoing
    end

  end

  describe 'when updating an outgoing message' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      @outgoing = @info_request.outgoing_messages.first
      @default_params = {:id => @outgoing.id,
                         :outgoing_message => {:prominence => 'hidden',
                                               :prominence_reason => 'dull',
                                               :body => 'changed body'} }
    end

    def make_request(params=@default_params)
      post :update, params
    end

    it 'should save a change to the body of the message' do
      make_request
      @outgoing.reload
      @outgoing.body.should == 'changed body'
    end

    it 'should save the prominence of the message' do
      make_request
      @outgoing.reload
      @outgoing.prominence.should == 'hidden'
    end

    it 'should save a prominence reason for the message' do
      make_request
      @outgoing.reload
      @outgoing.prominence_reason.should == 'dull'
    end

    it 'should log an "edit_outgoing" event on the info_request' do
      @controller.stub!(:admin_current_user).and_return("Admin user")
      make_request
      @info_request.reload
      last_event = @info_request.info_request_events.last
      last_event.event_type.should == 'edit_outgoing'
      last_event.params.should == { :outgoing_message_id => @outgoing.id,
                                    :editor => "Admin user",
                                    :old_prominence => "normal",
                                    :prominence => "hidden",
                                    :old_prominence_reason => nil,
                                    :old_body => 'Some information please',
                                    :body => 'changed body',
                                    :prominence_reason => "dull" }
    end

    it 'should expire the file cache for the info request' do
      @controller.should_receive(:expire_for_request).with(@info_request)
      make_request
    end

    context 'if the outgoing message saves correctly' do

      it 'should redirect to the admin info request view' do
        make_request
        response.should redirect_to admin_request_url(@info_request)
      end

      it 'should show a message that the incoming message has been updated' do
        make_request
        flash[:notice].should == 'Outgoing message successfully updated.'
      end

    end

    context 'if the incoming message is not valid' do

      it 'should render the edit template' do
        make_request({:id => @outgoing.id,
                      :outgoing_message => {:prominence => 'fantastic',
                                            :prominence_reason => 'dull',
                                            :body => 'Some information please'}})
        response.should render_template("edit")
      end

    end
  end

end

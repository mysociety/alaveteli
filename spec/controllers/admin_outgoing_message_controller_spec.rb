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
      expect(response).to be_success
    end

    it 'should assign the incoming message to the view' do
      get :edit, :id => @outgoing.id
      expect(assigns[:outgoing_message]).to eq(@outgoing)
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
      expect(@outgoing.body).to eq('changed body')
    end

    it 'should save the prominence of the message' do
      make_request
      @outgoing.reload
      expect(@outgoing.prominence).to eq('hidden')
    end

    it 'should save a prominence reason for the message' do
      make_request
      @outgoing.reload
      expect(@outgoing.prominence_reason).to eq('dull')
    end

    it 'should log an "edit_outgoing" event on the info_request' do
      allow(@controller).to receive(:admin_current_user).and_return("Admin user")
      make_request
      @info_request.reload
      last_event = @info_request.info_request_events.last
      expect(last_event.event_type).to eq('edit_outgoing')
      expect(last_event.params).to eq({ :outgoing_message_id => @outgoing.id,
                                    :editor => "Admin user",
                                    :old_prominence => "normal",
                                    :prominence => "hidden",
                                    :old_prominence_reason => nil,
                                    :old_body => 'Some information please',
                                    :body => 'changed body',
                                    :prominence_reason => "dull" })
    end

    it 'should expire the file cache for the info request' do
      expect(@controller).to receive(:expire_for_request).with(@info_request)
      make_request
    end

    context 'if the outgoing message saves correctly' do

      it 'should redirect to the admin info request view' do
        make_request
        expect(response).to redirect_to admin_request_url(@info_request)
      end

      it 'should show a message that the incoming message has been updated' do
        make_request
        expect(flash[:notice]).to eq('Outgoing message successfully updated.')
      end

    end

    context 'if the incoming message is not valid' do

      it 'should render the edit template' do
        make_request({:id => @outgoing.id,
                      :outgoing_message => {:prominence => 'fantastic',
                                            :prominence_reason => 'dull',
                                            :body => 'Some information please'}})
        expect(response).to render_template("edit")
      end

    end
  end

end

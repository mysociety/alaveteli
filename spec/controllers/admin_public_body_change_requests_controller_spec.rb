# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminPublicBodyChangeRequestsController, "editing a change request" do

  it "should render the edit template" do
    change_request = FactoryGirl.create(:add_body_request)
    get :edit, :id => change_request.id
    expect(response).to render_template("edit")
  end

end

describe AdminPublicBodyChangeRequestsController, 'updating a change request' do

  before do
    @change_request = FactoryGirl.create(:add_body_request)
  end

  it 'should close the change request' do
    post :update, { :id => @change_request.id }
    expect(PublicBodyChangeRequest.find(@change_request.id).is_open).to eq(false)
  end

  context 'when a response and subject are passed' do

    it 'should send a response email to the user who requested the change' do
      post :update, { :id => @change_request.id,
                      :response => 'Thanks but no',
                      :subject => 'Your request' }
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.subject).to eq('Your request')
      expect(mail.to).to eq([@change_request.get_user_email])
      expect(mail.body).to match(/Thanks but no/)
    end

  end

  context 'when no response or subject are passed' do

    it 'should send a response email to the user who requested the change' do
      post :update, { :id => @change_request.id }
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end
  end

end

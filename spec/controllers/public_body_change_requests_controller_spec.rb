# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyChangeRequestsController, "making a new change request" do

  it "should show the form" do
    get :new
    response.should render_template("new")
  end

end

describe PublicBodyChangeRequestsController, "creating a change request" do

  context 'when handling a request for a new authority' do

    before do
      @email = "test@example.com"
      name = "Test User"
      @change_request_params = {:user_email => @email,
                                :user_name => name,
                                :public_body_name => 'New Body',
                                :public_body_email => 'new_body@example.com',
                                :notes => 'Please',
                                :source => 'http://www.example.com',
                                :comment => '' }
    end

    it "should send an email to the site contact address" do
      post :create, {:public_body_change_request => @change_request_params}
      change_request_id = assigns[:change_request].id
      deliveries = ActionMailer::Base.deliveries
      deliveries.size.should == 1
      mail = deliveries[0]
      mail.subject.should =~ /Add authority - New Body/
      mail.from.should include(@email)
      mail.to.should include('postmaster@localhost')
      mail.body.should include('new_body@example.com')
      mail.body.should include('New Body')
      mail.body.should include("Please")
      mail.body.should include("http://test.host/admin/bodies/new?change_request_id=#{change_request_id}")
      mail.body.should include("http://test.host/admin/change_requests/#{change_request_id}/edit")
    end

    it 'should show a notice' do
      post :create, {:public_body_change_request => @change_request_params}
      expected_text = "Your request to add an authority has been sent. Thank you for getting in touch! We'll get back to you soon."
      flash[:notice].should == expected_text
    end

    it 'should redirect to the frontpage' do
      post :create, {:public_body_change_request => @change_request_params}
      response.should redirect_to frontpage_url
    end

    it 'has rudimentary spam protection' do
      spam_request_params = @change_request_params.merge({ :comment => 'I AM A SPAMBOT' })

      post :create, { :public_body_change_request => spam_request_params }

      response.should redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      deliveries.size.should == 0
      deliveries.clear
    end

  end

  context 'when handling a request for an update to an existing authority' do

    before do
      @email = "test@example.com"
      name = "Test User"
      @public_body = FactoryGirl.create(:public_body)
      @change_request_params = {:user_email => @email,
                                :user_name => name,
                                :public_body_id => @public_body.id,
                                :public_body_email => 'new_body@example.com',
                                :notes => 'Please',
                                :source => 'http://www.example.com',
                                :comment => '' }
    end

    it 'should send an email to the site contact address' do
      post :create, {:public_body_change_request => @change_request_params}
      change_request_id = assigns[:change_request].id
      deliveries = ActionMailer::Base.deliveries
      deliveries.size.should == 1
      mail = deliveries[0]
      mail.subject.should =~ /Update email address - #{@public_body.name}/
      mail.from.should include(@email)
      mail.to.should include('postmaster@localhost')
      mail.body.should include('new_body@example.com')
      mail.body.should include(@public_body.name)
      mail.body.should include("Please")
      mail.body.should include("http://test.host/admin/bodies/#{@public_body.id}/edit?change_request_id=#{change_request_id}")
      mail.body.should include("http://test.host/admin/change_requests/#{change_request_id}/edit")
    end

    it 'should show a notice' do
      post :create, {:public_body_change_request => @change_request_params}
      expected_text = "Your request to update the address for #{@public_body.name} has been sent. Thank you for getting in touch! We'll get back to you soon."
      flash[:notice].should == expected_text
    end

    it 'should redirect to the frontpage' do
      post :create, {:public_body_change_request => @change_request_params}
      response.should redirect_to frontpage_url
    end

  end


end

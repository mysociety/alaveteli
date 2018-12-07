# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::MessagesController do

  render_views

  it "should redirect to signin page if you go to the contact form and aren't signed in" do
    get :contact, params: { :id => users(:silly_name_user) }
    expect(response).
      to redirect_to(signin_path(:token => get_last_post_redirect.token))
  end

  it "should show contact form if you are signed in" do
    session[:user_id] = users(:bob_smith_user).id
    get :contact, params: { :id => users(:silly_name_user) }
    expect(response).to render_template('contact')
  end

  it "should give error if you don't fill in the subject" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, params: {
                     :id => users(:silly_name_user),
                     :contact => { :subject => "", :message => "Gah" },
                     :submitted_contact_form => 1
                   }
    expect(response).to render_template('contact')
  end

  context 'the site is configured to require a captcha' do
    before do
      allow(AlaveteliConfiguration).
        to receive(:user_contact_form_recaptcha).and_return(true)
      allow(controller).to receive(:verify_recaptcha).and_return(false)
    end

    it 'does not send the message without the recaptcha being completed' do
       session[:user_id] = users(:bob_smith_user).id
       post :contact, params: {
                          id: users(:silly_name_user).id,
                          contact: {
                            subject: 'Have some spam',
                            :message => 'Spam, spam, spam'
                          },
                          submitted_contact_form: 1 }

       deliveries = ActionMailer::Base.deliveries
       expect(deliveries.size).to eq(0)
       deliveries.clear
     end

  end

  it "should send the message" do
    session[:user_id] = users(:bob_smith_user).id
    post :contact, params: {
                     :id => users(:silly_name_user),
                     :contact => {
                       :subject => "Dearest you",
                       :message => "Just a test!"
                     },
                     :submitted_contact_form => 1
                   }
    expect(response).to redirect_to(user_url(users(:silly_name_user)))

    deliveries = ActionMailer::Base.deliveries
    expect(deliveries.size).to  eq(1)
    mail = deliveries[0]
    expect(mail.body).to include("Bob Smith has used #{AlaveteliConfiguration::site_name} to send you the message below")
    expect(mail.body).to include("Just a test!")
    #mail.to_addrs.first.to_s.should == users(:silly_name_user).name_and_email # TODO: fix some nastiness with quoting name_and_email
    expect(mail.header['Reply-To'].to_s).to match(users(:bob_smith_user).email)
  end

end

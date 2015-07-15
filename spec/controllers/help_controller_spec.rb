# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HelpController do
  render_views

  describe :index do

    it 'redirects to the about page' do
      get :index
      expect(response).to redirect_to(help_about_path)
    end

  end

  describe :about do

    it 'shows the about page' do
      get :about
      response.should be_success
      response.should render_template('help/about')
    end

  end

  describe 'GET contact' do

    it 'shows contact form' do
      get :contact
      response.should be_success
      response.should render_template('help/contact')
    end

    describe 'when requesting a page in a supported locale' do

      before do
        # Prepend our fixture templates
        fixture_theme_path = File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'theme_one')
        controller.prepend_view_path fixture_theme_path
      end

      it 'should render the locale-specific template if available' do
        get :contact, {:locale => 'es'}
        response.body.should match('contáctenos theme one')
      end

    end

  end

  describe 'POST contact' do

    it 'sends a contact message' do
      post :contact, { :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :comment => '',
                         :message => "You really should know!!!\n\nVinny" },
                       :submitted_contact_form => 1 }
      response.should redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      deliveries.size.should == 1
      deliveries[0].body.should include('really should know')
      deliveries.clear
    end

    it 'has rudimentary spam protection' do
      post :contact, { :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :comment => 'I AM A SPAMBOT',
                         :message => "You really should know!!!\n\nVinny" },
                       :submitted_contact_form => 1 }

      response.should redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      deliveries.size.should == 0
      deliveries.clear
    end

  end

end

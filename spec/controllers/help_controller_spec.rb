# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HelpController do
  render_views

  describe 'GET index' do

    it 'redirects to the about page' do
      get :index
      expect(response).to redirect_to(help_about_path)
    end

  end

  describe 'GET about' do

    it 'shows the about page' do
      get :about
      expect(response).to be_success
      expect(response).to render_template('help/about')
    end

  end

  describe 'GET contact' do

    it 'shows contact form' do
      get :contact
      expect(response).to be_success
      expect(response).to render_template('help/contact')
    end

    describe 'when requesting a page in a supported locale' do

      before do
        # Prepend our fixture templates
        fixture_theme_path = File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'theme_one')
        controller.prepend_view_path fixture_theme_path
      end

      it 'should render the locale-specific template if available' do
        get :contact, {:locale => 'es'}
        expect(response.body).to match('contáctenos theme one')
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
      expect(response).to redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      expect(deliveries[0].body).to include('really should know')
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

      expect(response).to redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      deliveries.clear
    end

  end

end

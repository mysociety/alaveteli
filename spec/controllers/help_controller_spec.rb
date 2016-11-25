# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HelpController do
  render_views

  describe 'GET #index' do

    it 'redirects to the about page' do
      get :index
      expect(response).to redirect_to(help_about_path)
    end

  end

  describe 'GET #unhappy' do
    let(:info_request){ FactoryGirl.create(:info_request) }

    it 'shows the unhappy template' do
      get :unhappy
      expect(response).to render_template('help/unhappy')
    end

    it 'does not assign an info_request' do
      get :unhappy
      expect(assigns[:info_request]).to be nil
    end

    context 'when a url_title param is supplied' do

      it 'assigns the info_request' do
        get :unhappy, :url_title => info_request.url_title
        expect(assigns[:info_request]).to eq info_request
      end

      it 'raises an ActiveRecord::RecordNotFound error if the InfoRequest
          is not found' do
        expect{ get :unhappy, :url_title => 'something_not_existing' }
          .to raise_error ActiveRecord::RecordNotFound
      end

      it 'raises an ActiveRecord::RecordNotFound error if the InfoRequest
          is embargoed' do
        info_request = FactoryGirl.create(:embargoed_request)
        expect{ get :unhappy, :url_title => info_request.url_title }
          .to raise_error ActiveRecord::RecordNotFound
      end
    end

  end

  describe 'GET #about' do

    it 'shows the about page' do
      get :about
      expect(response).to be_success
      expect(response).to render_template('help/about')
    end

  end

  describe 'GET #contact' do

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

    context 'when a url_title param is supplied' do
      let(:info_request){ FactoryGirl.create(:info_request) }

      it 'assigns the last request' do
        request.cookies["last_request_id"] = info_request.id
        get :contact
        expect(assigns[:last_request]).to eq info_request
      end

      it 'raises an ActiveRecord::RecordNotFound error if the InfoRequest
          is not found' do
        request.cookies["last_request_id"] = InfoRequest.maximum(:id)+1
        expect{ get :contact }
          .to raise_error ActiveRecord::RecordNotFound
      end

    end

  end

  describe 'POST #contact' do

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

    it 'renders the form when no params are supplied' do
      post :contact
      expect(response).to be_success
      expect(response).to render_template('help/contact')
    end

    it 'does not accept a form without a comment param' do
      post :contact, { :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :message => "You really should know!!!\n\nVinny" },
                       :submitted_contact_form => 1 }
      expect(response).to redirect_to(frontpage_path)
    end

  end

end

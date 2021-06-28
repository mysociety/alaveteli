require 'spec_helper'

describe HelpController do
  render_views

  describe 'GET #index' do

    it 'redirects to the about page' do
      get :index
      expect(response).to redirect_to(help_about_path)
    end

  end

  describe 'GET #unhappy' do
    let(:info_request) { FactoryBot.create(:info_request) }

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
        get :unhappy, params: { :url_title => info_request.url_title }
        expect(assigns[:info_request]).to eq info_request
      end

      it 'raises an ActiveRecord::RecordNotFound error if the InfoRequest
          is not found' do
        expect {
          get :unhappy, params: { :url_title => 'something_not_existing' }
        }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'raises an ActiveRecord::RecordNotFound error if the InfoRequest
          is embargoed' do
        info_request = FactoryBot.create(:embargoed_request)
        expect {
          get :unhappy, params: { :url_title => info_request.url_title }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

  end

  describe 'GET #about' do

    it 'shows the about page' do
      get :about
      expect(response).to be_successful
      expect(response).to render_template('help/about')
    end

  end

  describe 'GET #contact' do

    it 'shows contact form' do
      get :contact
      expect(response).to be_successful
      expect(response).to render_template('help/contact')
    end

    context 'when the user is a pro' do
      let(:pro_user) { FactoryBot.create(:pro_user) }

      before do
        session[:user_id] = pro_user.id
      end

      it 'sets @contact_email to the pro contact address' do
        with_feature_enabled(:alaveteli_pro) do
          get :contact
          expect(assigns[:contact_email]).
            to eq AlaveteliConfiguration.pro_contact_email
        end
      end
    end

    context 'when the user is a normal user' do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
      end

      it 'sets @contact_email to the normal contact address' do
        with_feature_enabled(:alaveteli_pro) do
          get :contact
          expect(assigns[:contact_email]).
            to eq AlaveteliConfiguration.contact_email
        end
      end
    end

    context 'when the user is logged out' do
      it 'sets @contact_email to the normal contact address' do
        with_feature_enabled(:alaveteli_pro) do
          get :contact
          expect(assigns[:contact_email]).
            to eq AlaveteliConfiguration.contact_email
        end
      end
    end

    describe 'when requesting a page in a supported locale' do

      before do
        # Prepend our fixture templates
        fixture_theme_path = File.join(Rails.root, 'spec', 'fixtures', 'theme_views', 'theme_one')
        controller.prepend_view_path fixture_theme_path
      end

      it 'should render the locale-specific template if available' do
        get :contact, params: { :locale => 'es' }
        expect(response.body).to match('contáctenos theme one')
      end

    end

    context 'when a last_request_id cookie is set' do
      let(:info_request) { FactoryBot.create(:info_request) }

      context "when the user can access the specified request" do
        it 'assigns @last_request' do
          request.cookies["last_request_id"] = info_request.id
          get :contact
          expect(assigns[:last_request]).to eq info_request
        end
      end

      context "when the user can't access the specified request" do
        it 'sets @last_request to nil' do
          info_request = FactoryBot.create(:embargoed_request)
          request.cookies["last_request_id"] = info_request.id
          get :contact
          expect(assigns[:last_request]).to be nil
        end
      end

      context "when the request cannot be found" do
        it 'sets @last_request to nil' do
          request.cookies["last_request_id"] = InfoRequest.maximum(:id)+1
          get :contact
          expect(assigns[:last_request]).to be nil
        end
      end
    end

    context 'when a last_body_id cookie is set' do
      let(:body) { FactoryBot.create(:public_body) }

      it 'assigns @last_body' do
        request.cookies["last_body_id"] = body.id
        get :contact
        expect(assigns[:last_body]).to eq body
      end

      context "when the body cannot be found" do
        it 'sets @last_body to nil' do
          request.cookies["last_body_id"] = PublicBody.maximum(:id)+1
          get :contact
          expect(assigns[:last_body]).to be nil
        end
      end
    end

  end

  describe 'POST #contact' do

    it 'sends a contact message' do
      post :contact, params: {
                       :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :comment => '',
                         :message => "You really should know!!!\n\nVinny"
                       },
                       :submitted_contact_form => 1
                     }
      expect(response).to redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      expect(deliveries[0].body).to include('really should know')
      deliveries.clear
    end

    context 'the site is configured to require reCAPTCHA' do

      before do
        allow(AlaveteliConfiguration).
          to receive(:contact_form_recaptcha).and_return(true)
        allow(controller).to receive(:verify_recaptcha).and_return(false)
      end

      it 'does not send the message without the recaptcha being completed' do
        post :contact, params: {
                         contact: {
                           name: 'Possible Spammmer',
                           email: 'spammer@localhost',
                           subject: 'Can I sell you my book?',
                           comment: '',
                           message: "It's great, you should buy 1!!"
                         },
                         submitted_contact_form: 1
                       }
        expect(response).not_to redirect_to(frontpage_path)

        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.size).to eq(0)
        deliveries.clear
      end

    end

    it 'has rudimentary spam protection' do
      post :contact, params: {
                       :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :comment => 'I AM A SPAMBOT',
                         :message => "You really should know!!!\n\nVinny"
                       },
                       :submitted_contact_form => 1
                     }

      expect(response).to redirect_to(frontpage_path)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      deliveries.clear
    end

    it 'renders the form when no params are supplied' do
      post :contact
      expect(response).to be_successful
      expect(response).to render_template('help/contact')
    end

    it 'does not accept a form without a comment param' do
      post :contact, params: {
                       :contact => {
                         :name => 'Vinny Vanilli',
                         :email => 'vinny@localhost',
                         :subject => 'Why do I have such an ace name?',
                         :message => "You really should know!!!\n\nVinny"
                       },
                       :submitted_contact_form => 1
                     }
      expect(response).to redirect_to(frontpage_path)
    end

  end

end

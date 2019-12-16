require 'spec_helper'

RSpec.describe CitationsController, type: :controller do
  before do
    allow(controller).to receive(:site_name).and_return('SITE')
  end

  shared_examples 'authorisation' do |opts|
    let(:ability) { Ability.new(user) }

    context 'when unable to read info request' do
      before do
        allow(controller).to receive(:cannot?).with(:read, info_request).
                          and_return(true)
      end

      it 'should find InfoRequest' do
        action
        expect(assigns[:info_request]).to eq info_request
      end

      it 'return a 404' do
        action
        expect(response.status).to eq 404
      end
    end

    shared_examples 'successful' do
      it 'assigns info_request' do
        action
        expect(assigns[:info_request]).to eq info_request
      end

      unless opts[:redirection]
        it 'should be successful' do
          action
          expect(response).to be_successful
        end
      end
    end

    # when requester
    include_examples 'successful'

    context 'when admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      include_examples 'successful'
    end

    context 'when pro' do
      let(:user) { FactoryBot.create(:pro_user) }
      include_examples 'successful'
    end

    context 'when not the requester' do
      let(:user) { FactoryBot.create(:user) }

      it 'assigns info_request' do
        begin
          action
        rescue CanCan::AccessDenied
        end
        expect(assigns[:info_request]).to eq info_request
      end

      it 'raise access denied' do
        expect {
          action
        }.to raise_error CanCan::AccessDenied
      end
    end
  end

  describe 'GET new' do
    context 'logged in' do
      let(:info_request) { FactoryBot.create(:info_request) }
      let(:user) { info_request.user }
      before { session[:user_id] = user.id }

      def action
        get :new, params: { url_title: info_request.url_title }
      end

      include_examples 'authorisation', redirection: false

      it 'assigns citation' do
        action
        expect(assigns[:citation]).to be_a Citation
      end

      it 'assigns user to citation' do
        action
        expect(assigns[:citation].user).to eq user
      end
    end

    context 'logged out' do
      it 'redirects to sign in form' do
        get :new, params: { url_title: 'request_title' }
        expect(response.status).to eq 302
      end

      it 'saves post redirect' do
        get :new, params: { url_title: 'request_title' }

        post_redirect = get_last_post_redirect
        expect(post_redirect.uri).to eq '/request/request_title/citations/new'
        expect(post_redirect.reason_params).to eq(
          web: 'To add a citation',
          email: 'Then you can add citations',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end

  describe 'POST create' do
    context 'logged in' do
      let(:info_request) { FactoryBot.create(:info_request) }
      let(:user) { info_request.user }
      before { session[:user_id] = user.id }

      def action
        post :create, params: {
          url_title: info_request.url_title,
          citation: params
        }
      end

      let(:params) do
        { source_url: 'http://example.com/news', type: 'news_story' }
      end

      include_examples 'authorisation', redirection: true

      it 'assigns citation' do
        action
        expect(assigns[:citation]).to be_a Citation
      end

      it 'assigns user to citation' do
        action
        expect(assigns[:citation].user).to eq user
      end

      it 'assigns info_request to citation' do
        action
        expect(assigns[:citation].citable).to eq info_request
      end

      context 'params valid' do
        it 'redirects back to request' do
          action
          expect(response).to redirect_to(
            show_request_url(url_title: info_request.url_title)
          )
        end

        it 'sets notice' do
          action
          expect(flash[:notice]).to eq 'Citation successfully created.'
        end
      end

      context 'params invalid' do
        let(:params) { { source_url: '', type: '' } }

        it 're-renders the new action' do
          action
          expect(response).to render_template :new
        end
      end
    end

    context 'logged out' do
      it 'redirects to sign in form' do
        post :create, params: { url_title: 'request_title' }
        expect(response.status).to eq 302
      end

      it 'saves post redirect' do
        post :create, params: { url_title: 'request_title' }

        post_redirect = get_last_post_redirect
        expect(post_redirect.uri).to eq '/request/request_title/citations'
        expect(post_redirect.reason_params).to eq(
          web: 'To add a citation',
          email: 'Then you can add citations',
          email_subject: 'Confirm your account on SITE'
        )
      end
    end
  end
end

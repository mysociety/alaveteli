require 'spec_helper'

RSpec.describe PublicTokensController, type: :controller do

  let(:ability) { Object.new.extend(CanCan::Ability) }
  let(:info_request) { FactoryBot.create(:embargoed_request) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  describe 'GET #show' do
    context 'when public token is valid and Info Request is readable' do
      before do
        allow(InfoRequest).to receive(:find_by!).and_return(info_request)
        ability.can :read, info_request
      end

      it 'finds Info Request by public token' do
        expect(InfoRequest).to receive(:find_by!).with(public_token: 'TOKEN')
        get :show, params: { public_token: 'TOKEN' }
      end

      it 'assigns info_request' do
        get :show, params: { public_token: 'TOKEN' }
        expect(assigns(:info_request)).to eq info_request
      end

      it 'adds noindex header' do
        get :show, params: { public_token: 'TOKEN' }
        expect(response.headers['X-Robots-Tag']).to eq 'noindex'
      end

      it 'returns http success' do
        get :show, params: { public_token: 'TOKEN' }
        expect(response).to be_successful
      end

      it 'returns request show template' do
        get :show, params: { public_token: 'TOKEN' }
        expect(response.body).to render_template('request/show')
      end
    end

    context 'when public token is valid and Info Request public' do
      let(:info_request) { FactoryBot.create(:info_request) }

      before do
        allow(InfoRequest).to receive(:find_by!).and_return(info_request)
      end

      it 'finds Info Request by public token' do
        expect(InfoRequest).to receive(:find_by!).with(public_token: 'TOKEN')
        get :show, params: { public_token: 'TOKEN' }
      end

      it 'redirects back to info request' do
        get :show, params: { public_token: 'TOKEN' }
        expect(response).to redirect_to(
          show_request_path(info_request.url_title)
        )
      end
    end

    context 'when public token is valid and Info Request is unreadable' do
      before do
        allow(InfoRequest).to receive(:find_by!).and_return(info_request)
        ability.cannot :read, info_request
      end

      it 'raises not found error' do
        expect { get :show, params: { public_token: 'TOKEN' } }.to(
          raise_error(ActiveRecord::RecordNotFound)
        )
      end
    end

    context 'when public token is invalid' do
      it 'raises not found error' do
        expect { get :show, params: { public_token: 'NOT-FOUND' } }.to(
          raise_error(ActiveRecord::RecordNotFound)
        )
      end
    end
  end

  describe 'POST #create' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(InfoRequest).to receive(:find_by!).with(url_title: 'URL_TITLE').
        and_return(info_request)
    end

    context 'with a logged in user who can share the info request' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.can :share, info_request
        allow(info_request).to receive(:public_token).and_return('ABC')
      end

      it 'enables the info requests public token' do
        expect(info_request).to receive(:enable_public_token!)
        post :create, params: { url_title: 'URL_TITLE' }
      end

      it 'sets a flash notice' do
        post :create, params: { url_title: 'URL_TITLE' }
        expect(flash.notice[:inline]).to match(
          %r(This request is now publicly accessible via <a[^>]+>[^<]+</a>)
        )
        expect(flash.notice[:inline]).to match(
          %r(http://test.host/r/ABC)
        )
      end

      it 'redirects back to info request' do
        post :create, params: { url_title: 'URL_TITLE' }
        expect(response).to redirect_to(
          show_request_path(info_request.url_title)
        )
      end
    end

    context 'with a logged in user who cannot share info request' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.cannot :share, info_request
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          post :create, params: { url_title: 'URL_TITLE' }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      it 'raises an CanCan::AccessDenied error' do
        expect {
          post :create, params: { url_title: 'URL_TITLE' }
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(InfoRequest).to receive(:find_by!).with(url_title: 'URL_TITLE').
        and_return(info_request)
    end

    context 'with a logged in user who can share the info request' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.can :share, info_request
      end

      it 'disables the info requests public token' do
        expect(info_request).to receive(:disable_public_token!)
        delete :destroy, params: { url_title: 'URL_TITLE' }
      end

      it 'sets a flash notice' do
        delete :destroy, params: { url_title: 'URL_TITLE' }
        expect(flash.notice).to eq 'The publicly accessible link for this ' \
                                   'request has now been disabled'
      end

      it 'redirects back to info request' do
        delete :destroy, params: { url_title: 'URL_TITLE' }
        expect(response).to redirect_to(
          show_request_path(info_request.url_title)
        )
      end
    end

    context 'with a logged in user who cannot share info request' do
      let(:user) { FactoryBot.create(:user) }

      before do
        sign_in user
        ability.cannot :share, info_request
      end

      it 'raises an CanCan::AccessDenied error' do
        expect {
          delete :destroy, params: { url_title: 'URL_TITLE' }
        }.to raise_error(CanCan::AccessDenied)
      end
    end

    context 'logged out' do
      it 'raises an CanCan::AccessDenied error' do
        expect {
          delete :destroy, params: { url_title: 'URL_TITLE' }
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

end

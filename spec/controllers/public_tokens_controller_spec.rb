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
        get :show, params: { id: 'TOKEN' }
      end

      it 'assigns info_request' do
        get :show, params: { id: 'TOKEN' }
        expect(assigns(:info_request)).to eq info_request
      end

      it 'returns http success' do
        get :show, params: { id: 'TOKEN' }
        expect(response).to be_successful
      end

      it 'returns plain message' do
        get :show, params: { id: 'TOKEN' }
        expect(response.body).to eq 'Success'
      end
    end

    context 'when public token is valid and Info Request public' do
      let(:info_request) { FactoryBot.create(:info_request) }

      before do
        allow(InfoRequest).to receive(:find_by!).and_return(info_request)
      end

      it 'finds Info Request by public token' do
        expect(InfoRequest).to receive(:find_by!).with(public_token: 'TOKEN')
        get :show, params: { id: 'TOKEN' }
      end

      it 'redirects back to info request' do
        get :show, params: { id: 'TOKEN' }
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
        expect { get :show, params: { id: 'TOKEN' } }.to(
          raise_error(ActiveRecord::RecordNotFound)
        )
      end
    end

    context 'when public token is invalid' do
      it 'raises not found error' do
        expect { get :show, params: { id: 'NOT-FOUND' } }.to(
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

    context 'when info request can be shared' do
      before do
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
  end

  describe 'DELETE #destroy' do
    let(:info_request) { FactoryBot.create(:info_request) }

    before do
      allow(InfoRequest).to receive(:find_by!).with(url_title: 'URL_TITLE').
        and_return(info_request)
    end

    context 'when info request can be shared' do
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
  end

end

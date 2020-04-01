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

      it 'renders hidden request template' do
        get :show, params: { public_token: 'TOKEN' }
        expect(response).to redirect_to("/request/#{info_request.url_title}")
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

end

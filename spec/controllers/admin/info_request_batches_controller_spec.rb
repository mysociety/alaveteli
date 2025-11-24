require 'spec_helper'

RSpec.describe Admin::InfoRequestBatchesController do
  before(:each) { sign_in(user) }

  let(:ability) { Object.new.extend(CanCan::Ability) }

  describe 'GET #show' do
    let(:batch) do
      FactoryBot.create(:info_request_batch)
    end

    let(:user) { FactoryBot.build(:user) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    context 'when the user can admin the batch' do
      before { ability.can :admin, batch }

      before do
        get :show, params: { id: batch.id }
      end

      it 'returns a successful response' do
        expect(response).to be_successful
      end

      it 'assigns the batch' do
        expect(assigns[:info_request_batch]).to eq(batch)
      end

      it 'assigns the requests' do
        get :show, params: { id: batch.id }
        expect(assigns[:info_requests]).to eq(batch.info_requests)
      end

      it 'renders the correct template' do
        expect(response).to render_template(:show)
      end
    end

    context 'with a large batch' do
      let(:batch) do
        FactoryBot.create(:info_request_batch, :sent, public_body_count: 105)
      end

      before { ability.can :admin, batch }

      it 'paginates the requests' do
        get :show, params: { id: batch.id }
        expect(assigns[:info_requests]).to eq(batch.info_requests.limit(100))
      end
    end

    context 'when the user cannot admin the batch' do
      before { ability.cannot :admin, batch }

      it 'returns a 404' do
        expect { get :show, params: { id: batch.id } }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

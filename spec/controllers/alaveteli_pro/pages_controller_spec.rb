# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::PagesController do

  describe 'GET #show' do

    context 'when asked for an existing template' do

      before do
        get :show, id: 'legal'
      end

      it 'renders the template' do
        expect(response).to render_template(:legal)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'sets in_pro_area' do
        expect(assigns(:in_pro_area)).to be true
      end
    end

    context 'when asked for a template that does not exist' do

      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :show, id: 'nope'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end

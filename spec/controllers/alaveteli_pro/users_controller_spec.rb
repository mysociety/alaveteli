# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::UsersController do

  describe 'POST #create' do

    context 'with pro pricing turned off' do

      it 'raises ActiveRecord::RecordNotFound' do
        expect { post :create }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context 'with pro pricing turned on' do

      before do
        with_feature_enabled(:pro_pricing) do
          post :create
        end
      end

      it 'renders the confirmation page' do
        expect(response).to render_template(:confirm)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

    end

  end

end

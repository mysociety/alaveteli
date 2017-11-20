# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Users::AccountsController do

  describe 'GET #show' do

    context 'with pro pricing turned off' do

      it 'raises ActiveRecord::RecordNotFound' do
        expect { get :show }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context 'with pro pricing turned on' do

      before do
        with_feature_enabled(:pro_pricing) do
          get :show
        end
      end

      it 'renders the show template' do
        expect(response).to render_template(:show)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

    end

  end

  describe 'GET #edit' do

    context 'with pro pricing turned off' do

      it 'raises ActiveRecord::RecordNotFound' do
        expect { get :edit }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context 'with pro pricing turned on' do

      before do
        with_feature_enabled(:pro_pricing) do
          get :edit
        end
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

    end

  end

  describe 'PATCH #update' do

    context 'with pro pricing turned off' do

      it 'raises ActiveRecord::RecordNotFound' do
        expect { patch :update }.to raise_error(ActiveRecord::RecordNotFound)
      end

    end

    context 'with pro pricing turned on' do

      context 'a successful update' do

        before do
          with_feature_enabled(:pro_pricing) do
            patch :update
          end
        end

        it 'redirects to the show action' do
          expect(response).to redirect_to(users_account_path)
        end

      end

      context 'an unsuccessful update' do

        before do
          with_feature_enabled(:pro_pricing) do
            patch :update
          end
        end

        skip 'renders the the edit form' do
          expect(response).to render(:edit)
        end

      end

    end

  end

end

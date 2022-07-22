require 'spec_helper'

RSpec.describe Admin::TagsController do
  describe 'GET index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

    it 'responds successfully' do
      get :index
      expect(response).to be_successful
    end

    it 'raise 404 for unknown types' do
      expect { get :index, params: { model_type: 'unknown' } }.to(
        raise_error ApplicationController::RouteNotFound
      )
    end

    def tags
      assigns[:tags].map(&:name_and_value)
    end

    it 'loads distinct tags' do
      FactoryBot.create(:public_body, tag_string: 'foo')
      FactoryBot.create(:public_body, tag_string: 'foo')

      get :index, params: { model_type: 'PublicBody' }
      expect(tags).to include('foo').once
    end

    context 'with taggable model type' do
      before { FactoryBot.create(:public_body, tag_string: 'bar') }

      it 'loads tags with correct type' do
        get :index, params: { model_type: 'PublicBody' }
        expect(tags).to include('bar')

        get :index, params: { model_type: 'InfoRequest' }
        expect(tags).to_not include('bar')
      end
    end

    context 'with a different taggable model type' do
      before { FactoryBot.create(:info_request, tag_string: 'bar') }

      it 'loads tags with correct type' do
        get :index, params: { model_type: 'PublicBody' }
        expect(tags).to_not include('bar')

        get :index, params: { model_type: 'InfoRequest' }
        expect(tags).to include('bar')
      end
    end
  end
end

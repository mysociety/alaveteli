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

    context 'with query' do
      before do
        FactoryBot.create(:public_body, tag_string: 'bar')
        FactoryBot.create(:public_body, tag_string: 'bar:123')
        FactoryBot.create(:public_body, tag_string: 'bar:124')
        FactoryBot.create(:public_body, tag_string: 'baz:123')
      end

      it 'filter tags with tag name query' do
        get :index, params: { model_type: 'PublicBody', query: 'bar' }
        expect(tags).to include('bar')
        expect(tags).to include('bar:123')
        expect(tags).to include('bar:124')
        expect(tags).to_not include('baz:123')
      end

      it 'filter tags with tag name/value query' do
        get :index, params: { model_type: 'PublicBody', query: 'bar:123' }
        expect(tags).to_not include('bar')
        expect(tags).to include('bar:123')
        expect(tags).to_not include('bar:124')
        expect(tags).to_not include('baz:123')
      end

      it 'filter tags with tag value query' do
        get :index, params: { model_type: 'PublicBody', query: ':123' }
        expect(tags).to_not include('bar')
        expect(tags).to include('bar:123')
        expect(tags).to_not include('bar:124')
        expect(tags).to include('baz:123')
      end
    end
  end

  describe 'GET show' do
    it 'renders the show template' do
      get :show, params: { tag: 'foo' }
      expect(response).to render_template('show')
    end

    it 'responds successfully' do
      get :show, params: { tag: 'foo' }
      expect(response).to be_successful
    end

    it 'raise 404 for unknown types' do
      expect { get :show, params: { model_type: 'unknown', tag: 'foo' } }.to(
        raise_error ApplicationController::RouteNotFound
      )
    end

    it 'loads notes' do
      note = FactoryBot.create(:note, notable_tag: 'foo')
      other_note = FactoryBot.create(:note, notable_tag: 'bar')

      get :show, params: { tag: 'foo' }
      expect(assigns[:notes]).to include(note).once
      expect(assigns[:notes]).to_not include(other_note)
    end

    def taggings
      assigns[:taggings]
    end

    it 'loads distinct taggings' do
      public_body = FactoryBot.create(:public_body, tag_string: 'foo foo:123')

      get :show, params: { model_type: 'PublicBody', tag: 'foo' }
      expect(taggings).to include(public_body).once
    end

    context 'with taggable model type' do
      let!(:public_body) { FactoryBot.create(:public_body, tag_string: 'bar') }

      it 'loads taggings with correct type' do
        get :show, params: { model_type: 'PublicBody', tag: 'bar' }
        expect(taggings).to include(public_body)

        get :show, params: { model_type: 'InfoRequest', tag: 'bar' }
        expect(taggings).to_not include(public_body)
      end
    end

    context 'with a different taggable model type' do
      let!(:info_request) do
        FactoryBot.create(:info_request, tag_string: 'bar')
      end

      it 'loads taggings with correct type' do
        get :show, params: { model_type: 'PublicBody', tag: 'bar' }
        expect(taggings).to_not include(info_request)

        get :show, params: { model_type: 'InfoRequest', tag: 'bar' }
        expect(taggings).to include(info_request)
      end
    end

    context 'with query' do
      let!(:pb_1) { FactoryBot.create(:public_body, tag_string: 'foo') }
      let!(:pb_2) { FactoryBot.create(:public_body, tag_string: 'foo bar:123') }
      let!(:pb_3) { FactoryBot.create(:public_body, tag_string: 'foo bar:124') }
      let!(:pb_4) { FactoryBot.create(:public_body, tag_string: 'foo baz:123') }

      it 'filter taggings with tag name query' do
        get :show, params: { model_type: 'PublicBody', tag: 'foo', query: 'bar' }
        expect(taggings).to_not include(pb_1)
        expect(taggings).to include(pb_2)
        expect(taggings).to include(pb_3)
        expect(taggings).to_not include(pb_4)
      end

      it 'filter taggings with tag name/value query' do
        get :show, params: { model_type: 'PublicBody', tag: 'foo', query: 'bar:123' }
        expect(taggings).to_not include(pb_1)
        expect(taggings).to include(pb_2)
        expect(taggings).to_not include(pb_3)
        expect(taggings).to_not include(pb_4)
      end

      it 'filter taggings with tag value query' do
        get :show, params: { model_type: 'PublicBody', tag: 'foo', query: ':123' }
        expect(taggings).to_not include(pb_1)
        expect(taggings).to include(pb_2)
        expect(taggings).to_not include(pb_3)
        expect(taggings).to include(pb_4)
      end
    end
  end
end

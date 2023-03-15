require 'spec_helper'

RSpec.describe Admin::BlogPostsController do
  describe 'GET index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template('index')
    end

    it 'responds successfully' do
      get :index
      expect(response).to be_successful
    end

    it 'loads blog posts' do
      post_1 = FactoryBot.create(:blog_post)
      post_2 = FactoryBot.create(:blog_post)
      get :index
      expect(assigns[:blog_posts]).to include(post_1, post_2)
    end

    it 'orders blog posts by descending ID' do
      expect(Blog::Post).to receive(:order).with(id: :desc).
        and_return(double.as_null_object)
      get :index
    end

    it 'paginates blog posts' do
      assoication = double.as_null_object
      allow(Blog::Post).to receive(:order).and_return(assoication)

      get :index
      expect(assoication).to have_received(:paginate).
        with(page: nil, per_page: 25)

      get :index, params: { page: 1 }
      expect(assoication).to have_received(:paginate).
        with(page: '1', per_page: 25)
    end
  end
end

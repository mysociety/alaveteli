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

  describe 'GET edit' do
    context 'blog post exists' do
      let(:blog_post) { FactoryBot.create(:blog_post) }

      it 'renders the edit template' do
        get :edit, params: { id: blog_post.id }
        expect(response).to render_template('edit')
      end

      it 'loads blog post by ID' do
        get :edit, params: { id: blog_post.id }
        expect(assigns[:blog_post]).to eq(blog_post)
      end

      it 'responds successfully' do
        get :edit, params: { id: blog_post.id }
        expect(response).to be_successful
      end
    end

    context 'blog post does not exists' do
      it 'returns a 404' do
        expect { get :edit, params: { id: 1 } }.to raise_error(
          ActiveRecord::RecordNotFound
        )
      end
    end
  end

  describe 'PATCH #update' do
    let(:blog_post) { FactoryBot.build(:blog_post, id: 1) }
    let(:params) { { tag_string: 'foo' } }

    before do
      allow(Blog::Post).to receive(:find).and_return(blog_post)
    end

    context 'when a successful update' do
      before do
        allow(blog_post).to receive(:update).and_return(true)
      end

      it 'assigns the blog post' do
        patch :update, params: { id: blog_post.id, blog_post: params }
        expect(assigns[:blog_post]).to eq(blog_post)
      end

      it 'sets a notice' do
        patch :update, params: { id: blog_post.id, blog_post: params }
        expect(flash[:notice]).to eq('Blog Post successfully updated.')
      end

      it 'redirects to the blog posts admin' do
        patch :update, params: { id: blog_post.id, blog_post: params }
        expect(response).to redirect_to(admin_blog_posts_path)
      end
    end

    context 'on an unsuccessful update' do
      before do
        allow(blog_post).to receive(:update).and_return(false)
      end

      it 'assigns the blog post' do
        patch :update, params: { id: blog_post.id, blog_post: params }
        expect(assigns[:blog_post]).to eq(blog_post)
      end

      it 'renders the form again' do
        patch :update, params: { id: blog_post.id, blog_post: params }
        expect(response).to render_template(:edit)
      end
    end
  end
end

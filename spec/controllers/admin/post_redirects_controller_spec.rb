require 'spec_helper'

RSpec.describe Admin::PostRedirectsController do
  let(:user) { FactoryBot.create(:admin_user) }

  before(:each) { sign_in(user) }

  describe 'DELETE #destroy' do
    let(:post_redirect) { FactoryBot.create(:post_redirect) }

    before do
      delete :destroy, params: { id: post_redirect.id }
    end

    it 'destroys the post redirect' do
      expect { post_redirect.reload }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'sets a notice' do
      expect(flash[:notice]).to eq('Post redirect successfully destroyed.')
    end

    it 'redirects to the admin page of the post redirect user' do
      expect(response).to redirect_to(admin_user_path(post_redirect.user))
    end
  end
end

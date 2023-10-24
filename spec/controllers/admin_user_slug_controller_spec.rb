require 'spec_helper'

RSpec.describe AdminUserSlugController do
  describe 'DELETE #destroy' do
    context 'user and user slug exists' do
      let(:user) { FactoryBot.create(:user) }
      let(:slug) { FriendlyId::Slug.create(slug: 'the-slug', sluggable: user) }

      it 'destroys slug belonging to user' do
        allow(User).to receive(:find).and_return(user)
        allow(user).to receive_message_chain(:slugs, :find).and_return(slug)

        expect(slug).to receive(:destroy)
        delete :destroy, params: { user_id: user.id, id: slug.id }
      end

      it 'redirects to admin user page' do
        delete :destroy, params: { user_id: user.id, id: slug.id }
        expect(response).to redirect_to([:admin, user])
      end
    end

    context 'slug is the users current one' do
      let(:user) { FactoryBot.create(:user) }
      let(:slug) { user.slugs.last }

      it 'does not destroy slug belonging to user' do
        allow(User).to receive(:find).and_return(user)
        allow(user).to receive_message_chain(:slugs, :find).and_return(slug)

        expect(slug).to_not receive(:destroy)
        delete :destroy, params: { user_id: user.id, id: slug.id }
      end

      it 'redirects to admin user page' do
        delete :destroy, params: { user_id: user.id, id: slug.id }
        expect(response).to redirect_to([:admin, user])
      end
    end

    context 'user does not exist' do
      it 'returns 404' do
        expect {
          delete :destroy, params: { user_id: 1, id: 1 }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'user slug does not exist' do
      let!(:user) { FactoryBot.create(:user) }

      it 'returns 404' do
        expect {
          delete :destroy, params: { user_id: user.id, id: 1 }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'user slug does not belong to user' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:mary) { FactoryBot.create(:user, name: 'Mary') }
      let!(:slug) { FriendlyId::Slug.create(slug: 'the-slug', sluggable: mary) }

      it 'returns 404' do
        expect {
          delete :destroy, params: { user_id: user.id, id: slug.id }
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end

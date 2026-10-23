require 'spec_helper'

RSpec.describe User::LoginToken do
  let(:user) { FactoryBot.create(:user) }
  let!(:post_redirect) { PostRedirect.create!(uri: '/', user: user) }
  let!(:other_post_redirect) do
    PostRedirect.create!(uri: '/', user: FactoryBot.create(:user))
  end

  context 'when the password changes' do
    before { user.update!(password: 'new-password') }

    it 'deletes the user post redirects' do
      expect(PostRedirect.exists?(post_redirect.id)).to eq(false)
    end

    it 'does not delete other user post redirects' do
      expect(PostRedirect.exists?(other_post_redirect.id)).to eq(true)
    end
  end

  context 'when the email changes' do
    before { user.update!(email: 'new@example.com') }

    it 'deletes the user post redirects' do
      expect(PostRedirect.exists?(post_redirect.id)).to eq(false)
    end
  end

  context 'when other attributes change' do
    before { user.update!(name: 'New Name') }

    it 'does not delete the user post redirects' do
      expect(PostRedirect.exists?(post_redirect.id)).to eq(true)
    end
  end
end

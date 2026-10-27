require 'spec_helper'

RSpec.describe LocalesController, type: :controller do
  before do
    AlaveteliLocalization.set_locales('es en', 'es')
  end

  describe 'PUT update' do
    it 'stores the locale in a cookie' do
      put :update, params: { locale: 'en', return_to: '/' }
      expect(cookies[:locale]).to eq('en')
    end

    it "updates the signed in user's locale" do
      user = FactoryBot.create(:user, locale: 'es')
      sign_in user
      put :update, params: { locale: 'en', return_to: '/' }
      expect(user.reload.locale).to eq('en')
    end

    it 'redirects to the return_to path' do
      put :update, params: { locale: 'en', return_to: '/body/foo' }
      expect(response).to redirect_to('/body/foo')
    end

    it 'redirects to the return_to path with a query string' do
      put :update, params: { locale: 'en', return_to: '/list?page=2' }
      expect(response).to redirect_to('/list?page=2')
    end

    it 'does not redirect to another host' do
      put :update, params: { locale: 'en', return_to: 'https://example.org/' }
      expect(response).to redirect_to(root_path)
    end

    it 'does not redirect to a protocol-relative URL' do
      put :update, params: { locale: 'en', return_to: '//example.org/' }
      expect(response).to redirect_to(root_path)
    end

    it 'redirects to the homepage without a return_to path' do
      put :update, params: { locale: 'en' }
      expect(response).to redirect_to(root_path)
    end
  end
end

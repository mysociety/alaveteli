# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/alaveteli_dsl')

describe 'Signing in with a redirect parameter', local_requests: false do

  context 'when not logged in' do
    let(:user) { FactoryBot.create(:user) }

    it 'redirects to an unprotected path' do
      login!(user, r: help_about_path)
      expect(response.status).to eq(200)
    end

    it 'redirects to an embargoed request that you own' do
      embargoed_request = FactoryBot.create(:embargoed_request, user: user)
      login!(user, r: show_request_path(embargoed_request.url_title))
      expect(response.status).to eq(200)
    end

    it 'renders a 404 when redirecting to an embargoed request that is not yours' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      login!(user, r: show_request_path(embargoed_request.url_title))
      expect(response.status).to eq(404)
    end

    pending 'does not redirect to external URLs' do
      login!(user, r: 'https://www.example.com/malicious')
      expect(response.status).to eq(404)
    end

  end

  context 'when already logged in' do
    let(:user) { FactoryBot.create(:user) }

    before do
      login!(user)
    end

    it 'redirects to an unprotected path' do
      login!(user, r: help_about_path)
      expect(response.status).to eq(200)
    end

    it 'redirects to an embargoed request that you own' do
      embargoed_request = FactoryBot.create(:embargoed_request, user: user)
      get signin_path, params: {
                         r: show_request_path(embargoed_request.url_title)
                       }
      follow_redirect!
      expect(response.status).to eq(200)
    end

    it 'renders a 404 when redirecting to an embargoed request that is not yours' do
      embargoed_request = FactoryBot.create(:embargoed_request)
      get signin_path, params: {
                         r: show_request_path(embargoed_request.url_title)
                       }
      follow_redirect!
      expect(response.status).to eq(404)
    end

    pending 'does not redirect to external URLs' do
      get signin_path, params: { r: 'https://www.example.com/malicious' }
      follow_redirect!
      expect(response.status).to eq(404)
    end
  end

end

def login!(user, params = {})
  params =
    { user_signin: { email: user.email, password: 'jonespassword' } }.
    merge(params)
  post signin_path, params: params
  follow_redirect!
end

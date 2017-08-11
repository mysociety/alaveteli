# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Users::SessionsController do

  describe 'GET new' do

    before do
      # Don't call out to external url during tests
      allow(controller).to receive(:country_from_ip).and_return('gb')
    end

    it "should show sign in / sign up page" do
      get :new
      expect(response.body).to render_template('user/sign')
    end

    it "should create post redirect to / when you just go to /signin" do
      get :new
      post_redirect = get_last_post_redirect
      expect(post_redirect.uri).to eq("/")
    end

    it "should create post redirect to /list when you click signin on /list" do
      get :new, :r => "/list"
      post_redirect = get_last_post_redirect
      expect(post_redirect.uri).to eq("/list")
    end
  end
end

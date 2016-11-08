# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::DashboardController do
  describe "#index" do
    let(:user) { FactoryGirl.create(:pro_user) }

    before do
      session[:user_id] = user.id
    end

    it "exists" do
      get :index
      expect(@response.status).to be 200
    end

    it "sets @user" do
      get :index
      expect(assigns[:user]).to eq user
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::DashboardController do
  describe "#index" do
    let(:user) { FactoryBot.create(:pro_user) }

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

    it 'assigns @page to 1 by default' do
      get :index
      expect(assigns[:page]).to eq 1
    end

    it 'does not set new_pro_user in flash' do
      expect(flash[:new_pro_user]).to be_nil
    end

    context 'if a page param is passed' do

      it 'assigns @page a numerical page param' do
        get :index, params: { page: 2 }
        expect(assigns[:page]).to eq 2
      end

      it 'does not assign a non-numerical page param' do
        get :index, params: { page: 'foo' }
        expect(assigns[:page]).to eq 1
      end
    end

    it 'assigns @per_page' do
      get :index
      expect(assigns[:per_page]).to eq 10
    end

    it 'assigns @activity_list' do
      get :index
      expect(assigns[:activity_list]).to be_a AlaveteliPro::ActivityList::List
    end

  end
end

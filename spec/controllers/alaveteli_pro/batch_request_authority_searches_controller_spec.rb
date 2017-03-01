# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::BatchRequestAuthoritySearchesController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }

  describe "#new" do
    before do
      session[:user_id] = pro_user.id
    end

    it "renders search_results.html.erb" do
      with_feature_enabled :alaveteli_pro do
        get :new
        expect(response).to render_template('search_results')
      end
    end
  end

  describe "#create" do
    let!(:authority_1) { FactoryGirl.create(:public_body) }
    let!(:authority_2) { FactoryGirl.create(:public_body) }
    let!(:authority_3) { FactoryGirl.create(:public_body) }

    before do
      session[:user_id] = pro_user.id
      update_xapian_index
    end

    it "performs a search" do
      get :create, query: 'Example Public Body'
      results = assigns[:search].results
      expect(results.count).to eq 3
      expect(results.first[:model].name).to eq authority_1.name
      expect(results.second[:model].name).to eq authority_2.name
      expect(results.third[:model].name).to eq authority_3.name
    end

    it "sets @query" do
      get :create, query: 'Example Public Body'
      expect(assigns[:query]).to eq 'Example Public Body'
    end

    it "sets @result_limit" do
      get :create, query: 'Example Public Body'
      expect(assigns[:result_limit]).to eq assigns[:search].matches_estimated
    end

    it "sets @page" do
      get :create, query: 'Example Public Body'
      expect(assigns[:page]).to eq 1
    end

    it "sets @per_page" do
      get :create, query: 'Example Public Body'
      expect(assigns[:per_page]).to eq 25
    end

    it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
      expect { get :create, query: 'Example Public Body', page: 21 }.
        to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

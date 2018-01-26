# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.describe AlaveteliPro::PublicBodiesController do

  describe "#index" do
    let!(:pro_user) { FactoryGirl.create(:pro_user) }
    let!(:body) { FactoryGirl.create(:public_body, :name => 'example') }
    let!(:defunct_body) do
      FactoryGirl.create(:defunct_public_body, :name => 'defunct')
    end
    let!(:not_apply_body) do
      FactoryGirl.create(:not_apply_public_body, :name => 'not_apply')
    end
    let!(:not_requestable_body) do
      FactoryGirl.create(:public_body, :name => 'not_requestable',
                                       :request_email => 'blank')
    end

    before do
      session[:user_id] = pro_user.id
      update_xapian_index
    end

    it "returns json" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: body.name
        expect(response.content_type).to eq("application/json")
      end
    end

    it "returns bodies which match the search query" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: body.name
        results = JSON.parse(response.body)
        expect(results[0]['name']).to eq(body.name)
      end
    end

    it "returns a whitelisted set of properties for each body" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: body.name
        results = JSON.parse(response.body)
        expected_keys = %w{id name notes info_requests_visible_count short_name
                           weight about html}
        expect(results[0].keys).to match_array(expected_keys)
      end
    end

    it "excludes defunct bodies" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: defunct_body.name
        results = JSON.parse(response.body)
        expect(results).to be_empty
      end
    end

    it "excludes not_apply bodies" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: not_apply_body.name
        results = JSON.parse(response.body)
        expect(results).to be_empty
      end
    end

    it "excludes bodies that aren't requestable" do
      with_feature_enabled :alaveteli_pro do
        get :index, query: not_requestable_body.name
        results = JSON.parse(response.body)
        expect(results).to be_empty
      end
    end
  end
end

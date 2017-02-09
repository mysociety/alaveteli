require 'spec_helper'

RSpec.describe AlaveteliPro::PublicBodiesController do

  describe "#search" do
    # Note: these specs rely on the global fixture data loaded by spec_helper
    # because they need public bodies to be indexed in Xapian
    let!(:pro_user) { FactoryGirl.create(:pro_user) }

    before do
      session[:user_id] = pro_user.id
    end

    it "returns json" do
      with_feature_enabled :alaveteli_pro do
        get :search, query: "department"
        expect(response.content_type).to eq("application/json")
      end
    end

    it "returns bodies which match the search query" do
      with_feature_enabled :alaveteli_pro do
        get :search, query: "Department for Humpadinking"
        results = JSON.parse(response.body)
        expect(results[0]['name']).to eq("Department for Humpadinking")
      end
    end

    it "returns a whitelisted set of properties for each body" do
      with_feature_enabled :alaveteli_pro do
        get :search, query: "Department for Humpadinking"
        results = JSON.parse(response.body)
        expected_keys = %w{id name notes info_requests_visible_count weight}
        expect(results[0].keys).to match_array(expected_keys)
      end
    end
  end
end

# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "creating a search" do
  it "performs a search" do
    results = assigns[:search].results
    expect(results.count).to eq 3
    expect(results.first[:model].name).to eq authority_1.name
    expect(results.second[:model].name).to eq authority_2.name
    expect(results.third[:model].name).to eq authority_3.name
  end

  it "sets @query" do
    expect(assigns[:query]).to eq 'Example'
  end

  it "sets @result_limit" do
    expect(assigns[:result_limit]).to eq assigns[:search].matches_estimated
  end

  it "sets @page" do
    expect(assigns[:page]).to eq 1
  end

  it "sets @per_page" do
    expect(assigns[:per_page]).to eq 25
  end
end

describe AlaveteliPro::BatchRequestAuthoritySearchesController do

  let(:pro_user) do
    user = FactoryGirl.create(:pro_user)
    AlaveteliFeatures.backend.enable_actor(:pro_batch_access, user)
    FactoryGirl.create(:pro_account,
                       user: user,
                       stripe_customer_id: 'test_customer',
                       monthly_batch_limit: 99)
    user
  end

  describe "#index" do
    let!(:authority_1) { FactoryGirl.create(:public_body) }
    let!(:authority_2) { FactoryGirl.create(:public_body) }
    let!(:authority_3) { FactoryGirl.create(:public_body) }

    before :all do
      get_fixtures_xapian_index
    end

    before do
      update_xapian_index
      session[:user_id] = pro_user.id
    end

    after do
      authority_1.destroy
      authority_2.destroy
      authority_3.destroy
      update_xapian_index
    end

    context "when responding to a normal request" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          get :index, authority_query: 'Example'
        end
      end

      it_behaves_like "creating a search"

      it "handles an empty query string" do
        with_feature_enabled(:alaveteli_pro) do
          get :index
          # No need for _search_result because no results
          expect(response).not_to render_template partial: '_search_result'
        end
      end

      it "renders index.html.erb" do
        expect(response).to render_template('index')
      end

      it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
        expect { get :index, authority_query: 'Example Public Body', page: 21 }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when responding to an ajax request" do
      before do
        with_feature_enabled :alaveteli_pro do
          xhr :get, :index, authority_query: 'Example'
        end
      end

      it_behaves_like "creating a search"

      it "handles an empty query string" do
        with_feature_enabled(:alaveteli_pro) do
          xhr :get, :index, authority_query: ''
          # No need for _search_result because no results
          expect(response).not_to render_template partial: '_search_result'
        end
      end

      it "only renders _search_results.html.erb" do
        expect(response).to render_template '_search_results'
        expect(response).not_to render_template('new')
      end

      it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
        expect { xhr :get, :index, authority_query: 'Example Public Body', page: 21 }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "the user does not have pro batch access" do

      let(:pro_user) { FactoryGirl.create(:pro_user) }

      it 'redirects them to the standard request form' do
        with_feature_enabled(:alaveteli_pro) do
          get :index
          expect(response).to redirect_to(new_alaveteli_pro_info_request_path)
        end
      end

    end

    context "the user has pro batch access but no remaining batch allowance" do

      let(:pro_user) do
        user = FactoryGirl.create(:pro_user)
        AlaveteliFeatures.backend.enable_actor(:pro_batch_access, user)
        FactoryGirl.create(:pro_account,
                           user: user,
                           stripe_customer_id: 'test_customer',
                           monthly_batch_limit: 0)
        user
      end

      it 'redirects them to the standard request form' do
        with_feature_enabled(:alaveteli_pro) do
          get :index
          expect(response).to redirect_to(new_alaveteli_pro_info_request_path)
        end
      end

    end

  end

  describe '#new' do

    before do
      session[:user_id] = pro_user.id
    end

    it 'redirects to index action' do
      get :new
      expect(response).to redirect_to(
        '/alaveteli_pro/batch_request_authority_searches'
      )
    end

    context "the user does not have pro batch access" do

      let(:pro_user) { FactoryGirl.create(:pro_user) }

      it 'redirects them to the standard request form' do
        with_feature_enabled(:alaveteli_pro) do
          get :new
          expect(response).to redirect_to(new_alaveteli_pro_info_request_path)
        end
      end

    end

  end

end

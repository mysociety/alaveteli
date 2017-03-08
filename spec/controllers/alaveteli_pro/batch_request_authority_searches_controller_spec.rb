# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "creating a search" do
  it "performs a search" do
    puts assigns[:search].results.inspect
    results = assigns[:search].results
    expect(results.count).to eq 3
    expect(results.first[:model].name).to eq authority_1.name
    expect(results.second[:model].name).to eq authority_2.name
    expect(results.third[:model].name).to eq authority_3.name
  end

  it "sets @query" do
    expect(assigns[:query]).to eq 'Example Public Body'
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
  let(:pro_user) { FactoryGirl.create(:pro_user) }

  describe "#new" do
    before do
      session[:user_id] = pro_user.id
    end

    it "renders new.html.erb" do
      with_feature_enabled :alaveteli_pro do
        get :new
        expect(response).to render_template('new')
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

    context "when responding to a normal request" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          get :create, query: 'Example Public Body'
        end
      end

      it_behaves_like "creating a search"

      it "renders new.html.erb" do
        expect(response).to render_template('new')
      end

      it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
        expect { get :create, query: 'Example Public Body', page: 21 }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when responding to an ajax request" do
      before do
        with_feature_enabled :alaveteli_pro do
          xhr :get, :create, query: 'Example Public Body'
        end
      end

      it_behaves_like "creating a search"

      it "only renders _search_results.html.erb" do
        expect(response).to render_template '_search_results'
        expect(response).not_to render_template('new')
      end

      it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
        expect { xhr :get, :create, query: 'Example Public Body', page: 21 }.
          to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end

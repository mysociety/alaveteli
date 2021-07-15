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
  let(:pro_user) { FactoryBot.create(:pro_user) }

  describe "#index" do
    let(:authority_1) { FactoryBot.build(:public_body) }
    let(:authority_2) { FactoryBot.build(:public_body) }
    let(:authority_3) { FactoryBot.build(:public_body) }

    before do
      get_fixtures_xapian_index
    end

    before do
      authority_1.save
      authority_2.save
      authority_3.save
      update_xapian_index
      session[:user_id] = pro_user.id
    end

    after do
      authority_1.destroy
      authority_2.destroy
      authority_3.destroy
      update_xapian_index
    end

    context 'without a draft_id param' do
      it 'initializes a draft if a draft_id was not provided' do
        get :index
        expect(assigns[:draft_batch_request]).to be_new_record
      end
    end

    context 'with a draft_id param' do
      it 'finds a draft by draft_id' do
        draft = FactoryBot.create(:draft_info_request_batch, user: pro_user)
        get :index, params: { draft_id: draft.id }
        expect(assigns[:draft_batch_request]).to eq(draft)
      end

      it 'initializes a draft if one cannot be found with the given draft_id' do
        max_id =
          AlaveteliPro::DraftInfoRequestBatch.maximum(:id).try(:next) || 99
        get :index, params: { draft_id: max_id }
        expect(assigns[:draft_batch_request]).to be_new_record
        expect(assigns[:draft_batch_request].user).to eq(pro_user)
      end
    end

    context "when responding to a normal request" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          get :index, params: { authority_query: 'Example' }
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
        expect {
          get :index, params: {
                        authority_query: 'Example Public Body',
                        page: 21
                      }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when responding to an ajax request" do
      before do
        with_feature_enabled :alaveteli_pro do
          get :index, xhr: true, params: { authority_query: 'Example' }
        end
      end

      it_behaves_like "creating a search"

      it "handles an empty query string" do
        with_feature_enabled(:alaveteli_pro) do
          get :index, xhr: true, params: { authority_query: '' }
          # No need for _search_result because no results
          expect(response).not_to render_template partial: '_search_result'
        end
      end

      it "only renders _search_results.html.erb" do
        expect(response).to render_template '_search_results'
        expect(response).not_to render_template('new')
      end

      it "raises WillPaginate::InvalidPage error for pages beyond the limit" do
        expect {
          get :index,
              xhr: true,
              params: {
                authority_query: 'Example Public Body',
                page: 21
              }
        }.to raise_error(ActiveRecord::RecordNotFound)
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
  end

end

require 'spec_helper'

describe AlaveteliPro::DraftInfoRequestBatchesController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:authority_1) { FactoryGirl.create(:public_body) }
  let(:authority_2) { FactoryGirl.create(:public_body) }
  let(:authority_3) { FactoryGirl.create(:public_body) }

  describe "#create" do
    before do
      session[:user_id] = pro_user.id
    end

    it "creates a new DraftInfoRequestBatch" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          alaveteli_pro_draft_info_request_batch: {
            title: 'Test Batch Request',
            body: 'This is a test batch request.',
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          }
        }
        expect { post :create, params }.
          to change {AlaveteliPro::DraftInfoRequestBatch.count }.by 1
      end
    end

    it "redirects to a new search if no query was provided" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          alaveteli_pro_draft_info_request_batch: {
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          }
        }
        post :create, params
        new_draft = pro_user.draft_info_request_batches.first
        expected_path = new_alaveteli_pro_batch_request_authority_search_path(
          draft_id: new_draft.id)
        expect(response).to redirect_to(expected_path)
      end
    end

    it "redirects to an existing search if a query is provided" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          alaveteli_pro_draft_info_request_batch: {
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          },
          query: "Department"
        }
        post :create, params
        new_draft = pro_user.draft_info_request_batches.first
        expected_path = alaveteli_pro_batch_request_authority_searches_path(
          draft_id: new_draft.id,
          query: "Department")
        expect(response).to redirect_to(expected_path)
      end
    end

    it "sets a :notice flash message" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          alaveteli_pro_draft_info_request_batch: {
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          },
          query: "Department"
        }
        post :create, params
        expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
      end
    end
  end

  describe "#update" do
    let(:draft) do
      FactoryGirl.create(:draft_info_request_batch, user: pro_user)
    end

    before do
      session[:user_id] = pro_user.id
    end

    it "updates the given DraftInfoRequestBatch" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          id: draft.id,
          alaveteli_pro_draft_info_request_batch: {
            title: 'Test Batch Request',
            body: 'This is a test batch request.',
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          }
        }
        put :update, params
        draft.reload
        expect(draft.title).to eq 'Test Batch Request'
        expect(draft.body).to eq 'This is a test batch request.'
        expect(draft.public_bodies).to eq [authority_1, authority_2, authority_3]
      end
    end

    context "if the user doesn't own the given draft" do
      let(:other_pro_user) { FactoryGirl.create(:pro_user) }

      before do
        session[:user_id] = other_pro_user.id
      end

      it "raises an ActiveRecord::RecordNotFound error" do
        with_feature_enabled(:alaveteli_pro) do
          params = {
            id: draft.id,
            alaveteli_pro_draft_info_request_batch: {
              title: 'Test Batch Request',
              body: 'This is a test batch request.',
              public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
            }
          }
          expect { put :update, params }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    it "redirects to a new search if no query was provided" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          id: draft.id,
          alaveteli_pro_draft_info_request_batch: {
            title: 'Test Batch Request',
            body: 'This is a test batch request.',
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          }
        }
        put :update, params
        expected_path = new_alaveteli_pro_batch_request_authority_search_path(
          draft_id: draft.id)
        expect(response).to redirect_to(expected_path)
      end
    end

    it "redirects to an existing search if a query is provided" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          id: draft.id,
          alaveteli_pro_draft_info_request_batch: {
            title: 'Test Batch Request',
            body: 'This is a test batch request.',
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          },
          query: "Department"
        }
        put :update, params
        expected_path = alaveteli_pro_batch_request_authority_searches_path(
          draft_id: draft.id,
          query: "Department")
        expect(response).to redirect_to(expected_path)
      end
    end

    it "sets a :notice flash message" do
      with_feature_enabled(:alaveteli_pro) do
        params = {
          id: draft.id,
          alaveteli_pro_draft_info_request_batch: {
            title: 'Test Batch Request',
            body: 'This is a test batch request.',
            public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
          },
          query: "Department"
        }
        put :update, params
        expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
      end
    end
  end
end

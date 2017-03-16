require 'spec_helper'

shared_examples_for "creating a request" do
  it "creates a new DraftInfoRequestBatch" do
    expect { subject }.
      to change {AlaveteliPro::DraftInfoRequestBatch.count }.by 1
  end
end

shared_examples_for "adding a body to a request" do
  it "adds the body" do
    subject
    draft.reload
    expect(draft.public_bodies).to eq [authority_1]
  end

  context "if the user doesn't own the given draft" do
    let(:other_pro_user) { FactoryGirl.create(:pro_user) }

    before do
      session[:user_id] = other_pro_user.id
    end

    it "raises an ActiveRecord::RecordNotFound error" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

shared_examples_for "removing a body from a request" do
  it "updates the given DraftInfoRequestBatch" do
    subject
    draft.reload
    expect(draft.public_bodies).to eq [authority_1]
  end

  context "if the user doesn't own the given draft" do
    let(:other_pro_user) { FactoryGirl.create(:pro_user) }

    before do
      session[:user_id] = other_pro_user.id
    end

    it "raises an ActiveRecord::RecordNotFound error" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

describe AlaveteliPro::DraftInfoRequestBatchesController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:authority_1) { FactoryGirl.create(:public_body) }
  let(:authority_2) { FactoryGirl.create(:public_body) }
  let(:authority_3) { FactoryGirl.create(:public_body) }

  describe "#create" do
    let(:params) do
      {
        alaveteli_pro_draft_info_request_batch: {
          title: 'Test Batch Request',
          body: 'This is a test batch request.',
          public_body_ids: authority_1.id
        },
        authority_query: "Department"
      }
    end

    before do
      session[:user_id] = pro_user.id
    end

    describe "when responding to a normal request" do
      subject do
        with_feature_enabled(:alaveteli_pro) do
          post :create, params
        end
      end

      it_behaves_like "creating a request"

      it "redirects to a new search if no query was provided" do
        params.delete(:authority_query)
        subject
        new_draft = pro_user.draft_info_request_batches.first
        expected_path = new_alaveteli_pro_batch_request_authority_search_path(
          draft_id: new_draft.id
        )
        expect(response).to redirect_to(expected_path)
      end

      it "redirects to an existing search if a query is provided" do
        subject
        new_draft = pro_user.draft_info_request_batches.first
        expected_path = alaveteli_pro_batch_request_authority_searches_path(
          draft_id: new_draft.id,
          authority_query: "Department"
        )
        expect(response).to redirect_to(expected_path)
      end

      it "sets a :notice flash message" do
        subject
        expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
      end
    end

    describe "when responding to an AJAX request" do
      subject do
        with_feature_enabled(:alaveteli_pro) do
          xhr :post, :create, params
        end
      end

      it_behaves_like "creating a request"

      it "renders the _summary.html.erb partial" do
        subject
        expect(response).to render_template("_summary")
      end
    end
  end

  describe "#update_bodies" do
    let(:draft) do
      FactoryGirl.create(:draft_info_request_batch, user: pro_user)
    end

    before do
      session[:user_id] = pro_user.id
    end

    describe "when adding a body" do
      let(:params) do
        {
          id: draft.id,
          add_body_id: authority_1.id
        }
      end

      describe "when responding to a normal request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, params
          end
        end

        it_behaves_like "adding a body to a request"

        it "redirects to a new search if no query was provided" do
          with_feature_enabled(:alaveteli_pro) do
            subject
            expected_path = new_alaveteli_pro_batch_request_authority_search_path(
              draft_id: draft.id)
            expect(response).to redirect_to(expected_path)
          end
        end

        it "redirects to an existing search if a query is provided" do
          with_feature_enabled(:alaveteli_pro) do
            params[:authority_query] = "Department"
            subject
            expected_path = alaveteli_pro_batch_request_authority_searches_path(
              draft_id: draft.id,
              authority_query: "Department")
            expect(response).to redirect_to(expected_path)
          end
        end

        it "sets a :notice flash message" do
          with_feature_enabled(:alaveteli_pro) do
            subject
            expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
          end
        end
      end

      describe "responding to an AJAX request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            xhr :put, :update_bodies, params
          end
        end

        it_behaves_like "adding a body to a request"

        it "renders the _summary.html.erb partial" do
          subject
          expect(response).to render_template("_summary")
        end
      end
    end

    describe "when removing a body" do
      let(:params) do
        {
          id: draft.id,
          remove_body_id: authority_2.id
        }
      end

      before do
        draft.public_bodies << [authority_1, authority_2]
      end

      describe "when responding to a normal request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, params
          end
        end

        it_behaves_like "removing a body from a request"

        it "redirects to a new search if no query was provided" do
          with_feature_enabled(:alaveteli_pro) do
            subject
            expected_path = new_alaveteli_pro_batch_request_authority_search_path(
              draft_id: draft.id)
            expect(response).to redirect_to(expected_path)
          end
        end

        it "redirects to an existing search if a query is provided" do
          with_feature_enabled(:alaveteli_pro) do
            params[:authority_query] = "Department"
            subject
            expected_path = alaveteli_pro_batch_request_authority_searches_path(
              draft_id: draft.id,
              authority_query: "Department")
            expect(response).to redirect_to(expected_path)
          end
        end

        it "sets a :notice flash message" do
          with_feature_enabled(:alaveteli_pro) do
            subject
            expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
          end
        end
      end

      describe "responding to an AJAX request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            xhr :put, :update_bodies, params
          end
        end

        it_behaves_like "removing a body from a request"

        it "renders the _summary.html.erb partial" do
          subject
          expect(response).to render_template("_summary")
        end
      end
    end
  end
end

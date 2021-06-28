require 'spec_helper'

shared_examples_for "creating a request" do
  it "creates a new DraftInfoRequestBatch" do
    expect { subject }.
      to change { AlaveteliPro::DraftInfoRequestBatch.count }.by 1
  end
end

shared_examples_for "adding a body to a request" do
  it "adds the body" do
    subject
    draft.reload
    expect(draft.public_bodies).to eq [authority_1]
  end

  context "if the user doesn't own the given draft" do
    let(:other_pro_user) { FactoryBot.create(:pro_user) }

    before do
      session[:user_id] = other_pro_user.id
    end

    it "creates new draft object" do
      subject
      expect(assigns[:draft]).to_not eq(draft)
      expect(assigns[:draft]).to be_a(AlaveteliPro::DraftInfoRequestBatch)
    end
  end
end

shared_examples_for "removing a body from a request" do
  it "updates the given DraftInfoRequestBatch" do
    subject
    draft.reload
    expect(draft.public_bodies).to eq [authority_1]
  end

  context 'if the draft is left with no authorities' do
    before do
      draft.public_bodies.delete(authority_1)
    end

    it 'deletes the draft' do
      subject
      expect(assigns[:draft]).to_not be_persisted
    end
  end

  context "if the user doesn't own the given draft" do
    let(:other_pro_user) { FactoryBot.create(:pro_user) }

    before do
      session[:user_id] = other_pro_user.id
    end

    it "raises an ActiveRecord::RecordNotFound error" do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

shared_examples_for 'respecting the selected page' do
  it "respects the selected page if one is provided" do
    params[:authority_query] = "Department"
    params[:page] = 2
    subject
    expected_path = alaveteli_pro_batch_request_authority_searches_path(
      draft_id: draft.id,
      authority_query: "Department",
      page: 2,
      mode: 'search'
    )
    expect(response).to redirect_to(expected_path)
  end
end

RSpec.describe AlaveteliPro::DraftInfoRequestBatchesController do
  let(:pro_user) { FactoryBot.create(:pro_user) }
  let(:authority_1) { FactoryBot.create(:public_body) }
  let(:authority_2) { FactoryBot.create(:public_body) }
  let(:authority_3) { FactoryBot.create(:public_body) }

  before do
    session[:user_id] = pro_user.id
  end

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

    let(:draft) { pro_user.draft_info_request_batches.first }

    describe "when responding to a normal request" do
      subject do
        with_feature_enabled(:alaveteli_pro) do
          post :create, params: params
        end
      end

      it_behaves_like "creating a request"
      it_behaves_like "respecting the selected page"

      it "redirects to a new search if no query was provided" do
        params.delete(:authority_query)
        subject
        expected_path = alaveteli_pro_batch_request_authority_searches_path(
          draft_id: draft.id,
          mode: 'search'
        )
        expect(response).to redirect_to(expected_path)
      end

      it "redirects to an existing search if a query is provided" do
        subject
        expected_path = alaveteli_pro_batch_request_authority_searches_path(
          draft_id: draft.id,
          authority_query: "Department",
          mode: 'search'
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
          post :create, xhr: true, params: params
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
      FactoryBot.create(:draft_info_request_batch, user: pro_user)
    end

    describe "when adding a body" do
      let(:params) do
        {
          alaveteli_pro_draft_info_request_batch: {
            draft_id: draft.id,
            public_body_id: authority_1.id,
            action: 'add'
          }
        }
      end

      describe "when responding to a normal request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, params: params
          end
        end

        it_behaves_like "adding a body to a request"

        it "redirects to a new search if no query was provided" do
          subject
          expected_path = alaveteli_pro_batch_request_authority_searches_path(
            draft_id: draft.id,
            mode: 'search'
          )
          expect(response).to redirect_to(expected_path)
        end

        it "redirects to an existing search if a query is provided" do
          params[:authority_query] = "Department"
          subject
          expected_path = alaveteli_pro_batch_request_authority_searches_path(
            draft_id: draft.id,
            authority_query: "Department",
            mode: 'search'
          )
          expect(response).to redirect_to(expected_path)
        end

        it_behaves_like "respecting the selected page"

        it "sets a :notice flash message" do
          subject
          expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
        end
      end

      describe "responding to an AJAX request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, xhr: true, params: params
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
          alaveteli_pro_draft_info_request_batch: {
            draft_id: draft.id,
            public_body_id: authority_2.id,
            action: 'remove'
          }
        }
      end

      before do
        draft.public_bodies << [authority_1, authority_2]
      end

      describe "when responding to a normal request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, params: params
          end
        end

        it_behaves_like "removing a body from a request"

        it "redirects to a new search if no query was provided" do
          subject
          expected_path = alaveteli_pro_batch_request_authority_searches_path(
            draft_id: draft.id,
            mode: 'search'
          )
          expect(response).to redirect_to(expected_path)
        end

        it "redirects to an existing search if a query is provided" do
          params[:authority_query] = "Department"
          subject
          expected_path = alaveteli_pro_batch_request_authority_searches_path(
            draft_id: draft.id,
            authority_query: "Department",
            mode: 'search'
          )
          expect(response).to redirect_to(expected_path)
        end

        it_behaves_like "respecting the selected page"

        it "sets a :notice flash message if the draft is persisted" do
          subject
          expect(flash[:notice]).to eq 'Your Batch Request has been saved!'
        end

        it 'redirects without the draft_id param if the draft is not persisted' do
          draft.public_bodies.delete(authority_1)
          subject
          expected_path = alaveteli_pro_batch_request_authority_searches_path(
            mode: 'search'
          )
          expect(response).to redirect_to(expected_path)
        end

        it "does not set a :notice flash message if the draft is not persisted" do
          draft.public_bodies.delete(authority_1)
          subject
          expect(flash[:notice]).to be_nil
        end
      end

      describe "responding to an AJAX request" do
        subject do
          with_feature_enabled(:alaveteli_pro) do
            put :update_bodies, xhr: true, params: params
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

  describe "#update" do
    let(:draft) do
      FactoryBot.create(:draft_info_request_batch, user: pro_user)
    end
    let(:params) do
      {
        alaveteli_pro_draft_info_request_batch: {
          title: 'Test Batch Request',
          body: 'This is a test batch request.',
          embargo_duration: '3_months',
          public_body_ids: [authority_1.id, authority_2.id, authority_3.id]
        },
        id: draft.id
      }
    end

    it "updates the draft" do
      put :update, params: params
      draft.reload
      expect(draft.title).to eq 'Test Batch Request'
      expect(draft.body).to eq 'This is a test batch request.'
      expect(draft.public_bodies).to match_array([authority_1, authority_2, authority_3])
      expect(draft.embargo_duration).to eq '3_months'
    end

    context "when the user is previewing" do
      before do
        params[:preview] = '1'
      end

      it "redirects to the batch preview page" do
        put :update, params: params
        expected_path = preview_new_alaveteli_pro_info_request_batch_path(
          draft_id: draft.id
        )
        expect(response).to redirect_to(expected_path)
      end
    end

    context "when the user is saving" do
      it "redirects to the new batch page" do
        put :update, params: params
        expected_path = new_alaveteli_pro_info_request_batch_path(
          draft_id: draft.id
        )
        expect(response).to redirect_to(expected_path)
      end
    end
  end
end

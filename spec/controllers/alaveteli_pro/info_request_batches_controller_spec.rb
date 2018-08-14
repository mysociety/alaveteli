# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for "an info_request_batch action" do
  it "sets @draft_info_request_batch from the draft_id param" do
    with_feature_enabled(:alaveteli_pro) do
      action
      expect(assigns[:draft_info_request_batch]).to eq draft
    end
  end

  context "if the specified draft doesn't exist" do
    it "raises ActiveRecord::RecordNotFound" do
      with_feature_enabled(:alaveteli_pro) do
        params[:draft_id] = AlaveteliPro::DraftInfoRequestBatch.maximum(:id).next
        expect { action }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "if the current_user doesn't own the specified draft" do
    before do
      session[:user_id] = other_user.id
    end

    it "raises ActiveRecord::RecordNotFound" do
      with_feature_enabled(:alaveteli_pro) do
        expect { action }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  it "sets @info_request_batch" do
    with_feature_enabled(:alaveteli_pro) do
      action
      expect(assigns[:info_request_batch]).not_to be_nil
      expect(assigns[:info_request_batch].public_bodies).to match_array(bodies)
      expect(assigns[:info_request_batch].title).to eq draft.title
      expect(assigns[:info_request_batch].body).to eq draft.body
    end
  end

  it "sets @example_info_request" do
    with_feature_enabled(:alaveteli_pro) do
      action
      expect(assigns[:example_info_request]).not_to be_nil
      expect(bodies.include?(assigns[:example_info_request].public_body)).
        to be true
      expect(assigns[:example_info_request].title).to eq draft.title
    end
  end

  it "sets @outgoing_message" do
    with_feature_enabled(:alaveteli_pro) do
      action
      expect(assigns[:outgoing_message]).not_to be_nil
      expected_body = draft.body.gsub('[Authority name]', body_1.name)
      expect(assigns[:outgoing_message].body).to eq expected_body
    end
  end

  context "when an embargo_duration is set on the draft" do
    before do
      draft.embargo_duration = "12_months"
      draft.save
    end

    it "sets @embargo to an embargo with the same emabrgo_duration" do
      with_feature_enabled(:alaveteli_pro) do
        action
        expect(assigns[:embargo]).not_to be_nil
        expect(assigns[:embargo].embargo_duration).to eq "12_months"
      end
    end
  end

  context "when the embargo_duration is set to publish immediately on the draft" do
    before do
      draft.embargo_duration = ""
      draft.save
    end

    it "does not set @embargo" do
      with_feature_enabled(:alaveteli_pro) do
        action
        expect(assigns[:embargo]).to be_nil
      end
    end
  end

  context "when no embargo_duration is set on the draft" do
    before do
      draft.embargo_duration = nil
      draft.save
    end

    it "does not set @embargo" do
      with_feature_enabled(:alaveteli_pro) do
        action
        expect(assigns[:embargo]).to be_nil
      end
    end
  end
end

describe AlaveteliPro::InfoRequestBatchesController do
  let(:body_1) { FactoryBot.create(:public_body) }
  let(:body_2) { FactoryBot.create(:public_body) }
  let(:bodies) { [body_1, body_2] }
  let(:user) { FactoryBot.create(:pro_user) }
  let(:other_user) { FactoryBot.create(:pro_user) }
  let!(:draft) do
    FactoryBot.create(:draft_info_request_batch,
                      public_bodies: bodies,
                      user: user)
  end
  let(:params) { {draft_id: draft.id} }

  before do
    session[:user_id] = user.id
  end

  describe "#new" do
    let(:action) { get :new, params }

    it_behaves_like "an info_request_batch action"

    it "renders alaveteli_pro/info_requests/new.html.erb" do
      with_feature_enabled(:alaveteli_pro) do
        action
        expect(response).to render_template("alaveteli_pro/info_requests/new")
      end
    end
  end

  describe "#preview" do
    let(:action) { get :preview, params }

    it_behaves_like "an info_request_batch action"

    context "when everything is valid" do
      it "renders alaveteli_pro/info_requests/preview.html.erb" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(response).to render_template("alaveteli_pro/info_requests/preview")
        end
      end
    end

    context "when the draft is not valid" do
      before do
        draft.body = ""
        draft.title = ""
        draft.save
      end

      it "removes duplicate errors" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(assigns[:info_request_batch].errors).to be_empty
          expect(assigns[:example_info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:example_info_request].errors[:title]).not_to be_empty
          expect(assigns[:outgoing_message].errors[:body]).not_to be_empty
        end
      end

      it "renders alaveteli_pro/info_requests/new.html.erb" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(response).to render_template("alaveteli_pro/info_requests/new")
        end
      end
    end
  end


  describe "#create" do
    let(:params) { {draft_id: draft.id} }
    let(:action) { post :create, params }

    it_behaves_like "an info_request_batch action"

    context "when everything is valid" do
      it "creates an info_request_batch" do
        with_feature_enabled(:alaveteli_pro) do
          expect { action }.to change { InfoRequestBatch.count }.by(1)
          new_batch = InfoRequestBatch.order(created_at: :desc).first
          expect(new_batch.title).to eq draft.title
          expect(new_batch.public_bodies).to match_array(draft.public_bodies)
          expect(new_batch.body).to eq draft.body
          expect(new_batch.embargo_duration).to eq draft.embargo_duration
        end
      end

      it "destroys the draft" do
        with_feature_enabled(:alaveteli_pro) do
          title = draft.title
          expect { action }.to change { AlaveteliPro::DraftInfoRequestBatch.count }.by(-1)
          expect(AlaveteliPro::DraftInfoRequestBatch.where(title: title))
        end
      end

      it "redirects to show the batch" do
        with_feature_enabled(:alaveteli_pro) do
          action
          new_batch = InfoRequestBatch.order(created_at: :desc).first
          expect(response).to redirect_to(show_alaveteli_pro_batch_request_path(new_batch.id))
        end
      end
    end

    context 'when a user is below the rate limit' do
      before(:each) do
        limiter = double
        allow(limiter).to receive(:record)
        allow(limiter).to receive(:limit?).and_return(false)
        allow(controller).to receive(:rate_monitor).and_return(limiter)
      end

      it 'does not send a notification' do
        action
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when a user hits the rate limit' do
      before(:each) do
        limiter = double
        allow(limiter).to receive(:record)
        allow(limiter).to receive(:limit?).and_return(true)
        allow(controller).to receive(:rate_monitor).and_return(limiter)
      end

      it 'sends a notification' do
        action
        mail = ActionMailer::Base.deliveries.first
        expect(mail.subject).to match(/Batch rate limit hit/)
      end
    end

    context "when the draft is not valid" do
      before do
        draft.body = ""
        draft.title = ""
        draft.save
      end

      it "removes duplicate errors" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(assigns[:info_request_batch].errors).to be_empty
          expect(assigns[:example_info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:example_info_request].errors[:title]).not_to be_empty
          expect(assigns[:outgoing_message].errors[:body]).not_to be_empty
        end
      end

      it "renders alaveteli_pro/info_requests/new.html.erb" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(response).to render_template("alaveteli_pro/info_requests/new")
        end
      end
    end
  end
end

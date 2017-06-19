# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::InfoRequestsController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }

  describe "GET #index" do
    let!(:info_request) do
      request = nil
      TestAfterCommit.with_commits(true) do
        request = FactoryGirl.create(:info_request, :user => pro_user)
      end
      request
    end

    let!(:foo_request) do
      request = nil
      TestAfterCommit.with_commits(true) do
        request = FactoryGirl.create(:info_request, :user => pro_user,
                                                    :title => 'Foo foo')
      end
      request
    end

    before do
      session[:user_id] = info_request.user.id
    end

    it "exists" do
      get :index
      expect(response.status).to be 200
    end

    it "assigns a request filter" do
      get :index
      expect(assigns[:request_filter]).to be_a AlaveteliPro::RequestFilter
    end

    context 'when no filters, searches or sort params are passed' do

      it "assigns the user's request summaries" do
        get :index
        expect(assigns[:request_summaries].size).to eq 2
        expect(assigns[:request_summaries]).
          to match_array [info_request.request_summary, foo_request.request_summary]
      end
    end

    context 'when a search is passed' do

      it 'applies the search' do
        get :index, {:alaveteli_pro_request_filter => {:search => 'foo'}}
        expect(assigns[:request_summaries].size).to eq 1
      end

    end

  end

  describe "#preview" do
    let(:draft) do
      FactoryGirl.create(:draft_info_request, body: nil, user: pro_user)
    end

    context "when there are errors on the outgoing message" do
      it "removes duplicate errors from the info_request" do
        session[:user_id] = pro_user.id
        with_feature_enabled(:alaveteli_pro) do
          post :preview, draft_id: draft
          expect(assigns[:info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:outgoing_message].errors).not_to be_empty
        end
      end
    end
  end

  describe "#create" do
    let(:draft) do
      FactoryGirl.create(:draft_info_request, body: nil, user: pro_user)
    end

    context "when there are errors on the outgoing message" do
      it "removes duplicate errors from the info_request" do
        session[:user_id] = pro_user.id
        with_feature_enabled(:alaveteli_pro) do
          post :create, draft_id: draft
          expect(assigns[:info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:outgoing_message].errors).not_to be_empty
        end
      end
    end
  end

  describe "#update" do
    let(:pro_user) { FactoryGirl.create(:pro_user) }
    let(:other_pro_user) { FactoryGirl.create(:pro_user) }
    let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }

    context "when the user is not allowed to update the request" do
      it "raises a CanCan::AccessDenied error" do
        session[:user_id] = other_pro_user.id
        expect do
          put :update, id: info_request.id,
                       info_request: { described_state: "successful" }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end

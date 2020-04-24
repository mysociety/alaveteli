# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::InfoRequestsController do
  let(:pro_user) { FactoryBot.create(:pro_user) }

  describe "GET #index" do
    let!(:info_request) do
      FactoryBot.create(:info_request, user: pro_user)
    end

    let!(:foo_request) do
      FactoryBot.create(:info_request, user: pro_user, title: 'Foo foo')
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
        get :index, params: { :alaveteli_pro_request_filter => {
                                :search => 'foo'
                              }
                            }
        expect(assigns[:request_summaries].size).to eq 1
      end

    end

  end

  describe "#preview" do
    let(:draft) do
      FactoryBot.create(:draft_info_request, body: nil, user: pro_user)
    end

    context "when there are errors on the outgoing message" do
      it "removes duplicate errors from the info_request" do
        session[:user_id] = pro_user.id
        with_feature_enabled(:alaveteli_pro) do
          post :preview, params: { draft_id: draft }
          expect(assigns[:info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:outgoing_message].errors).not_to be_empty
        end
      end
    end

    context "when the public body is not requestable" do
      let(:public_body) { FactoryBot.create(:public_body, :defunct) }
      let(:draft) do
        FactoryBot.create(:draft_info_request, public_body: public_body,
                                               user: pro_user)
      end

      it "renders a message to tell the user" do
        session[:user_id] = pro_user.id
        with_feature_enabled(:alaveteli_pro) do
          post :preview, params: { draft_id: draft }
          expect(response).to render_template('request/new_defunct.html.erb')
        end
      end
    end
  end

  describe "#create" do
    let(:draft) do
      FactoryBot.create(:draft_info_request, body: nil, user: pro_user)
    end

    context "when there are errors on the outgoing message" do
      it "removes duplicate errors from the info_request" do
        session[:user_id] = pro_user.id
        with_feature_enabled(:alaveteli_pro) do
          post :create, params: { draft_id: draft }
          expect(assigns[:info_request].errors[:outgoing_messages]).to be_empty
          expect(assigns[:outgoing_message].errors).not_to be_empty
        end
      end
    end
  end
end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::InfoRequestsController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }

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
end

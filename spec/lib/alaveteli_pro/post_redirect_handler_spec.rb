require 'spec_helper'

describe AlaveteliPro::PostRedirectHandler, type: :controller do
  controller do
    include AlaveteliPro::PostRedirectHandler
  end

  describe "#override_post_redirect_for_pro" do
    context "when the uri matches /<locale>/new" do
      let(:uri) { '/en/new' }
      let(:user) { FactoryBot.create(:pro_user) }
      let(:post_redirect) do
        FactoryBot.create(:new_request_post_redirect, user: user, uri: uri)
      end

      it "creates a draft info request" do
        params = post_redirect.post_params
        expect {
          controller.override_post_redirect_for_pro(uri, post_redirect, user)
        }.to change { DraftInfoRequest.count }.by(1)
        draft = DraftInfoRequest.last
        expect(draft.user).to eq(user)
        expect(draft.title).to eq(params["info_request"]["title"])
        expect(draft.body).to eq(params["outgoing_message"]["body"])
        expect(draft.public_body_id).to eq(params["info_request"]["public_body_id"].to_i)
      end

      it "overrides the uri" do
        expect(
          controller.override_post_redirect_for_pro(uri, post_redirect, user)
        ).to match /#{new_alaveteli_pro_info_request_path}\?draft_id=\d+/
      end
    end

    context "when the uri does not match /<locale>/new" do
      let(:uri) { '/en/new/public_body' }
      let(:user) { FactoryBot.create(:pro_user) }
      let(:post_redirect) do
        FactoryBot.create(:post_redirect, user: user, uri: uri)
      end

      it "does not override the uri" do
        expect(
          controller.override_post_redirect_for_pro(uri, post_redirect, user)
        ).to eq uri
      end
    end
  end
end

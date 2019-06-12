# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::BaseController do
  controller(AlaveteliPro::BaseController) do
    def index
      head :ok
    end
  end

  describe "#pro_user_authenticated?" do
    # Testing the fact that every controller action inherits the before_action
    # of pro_user_authenticated?

    before do
      allow(controller).to receive(:feature_enabled?).with(:alaveteli_pro).and_return(true)
    end

    context "when the user is not logged in" do
      it "redirects to the signin path" do
        get :index
        expect(@response.redirect_url).to match(/http:\/\/test\.host\/profile\/sign_in/)
      end
    end

    context "when the user is logged in but not a pro" do
      let(:user) { FactoryBot.create(:user) }

      before do
        session[:user_id] = user.id
      end

      it "redirects to the homepage" do
        get :index
        expect(@response).to redirect_to frontpage_path
      end

      it "sets a flash notice to inform the user they're not a pro" do
        get :index
        expect(flash[:notice]).to eq "This page is only accessible to " \
                                     "Alaveteli Professional users"
      end
    end

    context "when the user is logged in and is a pro" do
      let(:user) { FactoryBot.create(:pro_user) }

      before do
        session[:user_id] = user.id
      end

      it "doesn't redirect anywhere" do
        get :index
        expect(@response.status).to be 200
      end
    end
  end
end

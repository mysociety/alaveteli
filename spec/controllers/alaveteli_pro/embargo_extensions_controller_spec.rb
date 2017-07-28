# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::EmbargoExtensionsController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:admin) do
    user = FactoryGirl.create(:pro_admin_user)
    user.roles << Role.find_by(name: 'pro')
    user
  end
  let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }
  let(:embargo) { FactoryGirl.create(:embargo, info_request: info_request) }

  describe "#create" do
    context "when the user is allowed to update the embargo" do
      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create,
                 alaveteli_pro_embargo_extension:
                   { embargo_id: embargo.id,
                     extension_duration: "3_months" }
          end
        end

        it "updates the embargo" do
          expect(embargo.reload.publish_at).
            to eq AlaveteliPro::Embargo.six_months_from_now
        end

        it "sets a flash message" do
          expect(flash[:notice]).
            to eq "Your request will now be private on Alaveteli until " \
                  "#{AlaveteliPro::Embargo.six_months_from_now.strftime('%d %B %Y')}."
        end

        it "redirects to the request show page" do
          expect(response).
            to redirect_to show_alaveteli_pro_request_path(
              url_title: info_request.url_title)
        end
      end

      context "because they are an admin" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :create,
                 alaveteli_pro_embargo_extension:
                   { embargo_id: embargo.id,
                     extension_duration: "3_months" }
          end
        end

        it "updates the embargo" do
          expect(embargo.reload.publish_at).
            to eq AlaveteliPro::Embargo.six_months_from_now
        end

        it "sets a flash message" do
          expect(flash[:notice]).
            to eq "Your request will now be private on Alaveteli until " \
                  "#{AlaveteliPro::Embargo.six_months_from_now.strftime('%d %B %Y')}."
        end

        it "redirects to the request show page" do
          expect(response).
            to redirect_to show_alaveteli_pro_request_path(
              url_title: info_request.url_title)
        end
      end
    end

    context "when the user is not allowed to update the embargo" do
      before do
        other_user = FactoryGirl.create(:pro_user)
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = other_user.id
        end
      end

      it "raises a CanCan::AccessDenied error" do
        expect do
          post :create,
               alaveteli_pro_embargo_extension:
                 { embargo_id: embargo.id,
                   extension_duration: "3_months" }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when the extension is invalid" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          post :create,
               alaveteli_pro_embargo_extension: { embargo_id: embargo.id }
        end
      end

      it "sets a flash error message" do
        expect(flash[:error]).to eq "Sorry, something went wrong updating " \
                                    "your request's privacy settings, " \
                                    "please try again."
      end
    end
  end
end

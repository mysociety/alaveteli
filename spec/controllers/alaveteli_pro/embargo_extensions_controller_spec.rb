# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::EmbargoExtensionsController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:admin) { FactoryGirl.create(:admin_user) }
  let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }
  let(:embargo) { FactoryGirl.create(:embargo, info_request: info_request) }

  describe "#create" do
    context "when the user is allowed to update the embargo" do
      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create,
                 embargo_extension: { embargo_id: embargo.id,
                                      extension_duration: "3_months" }
          end
        end

        it "updates the embargo" do
          expect(embargo.reload.publish_at.to_date).to eq Time.zone.today + 6.months
        end

        it "sets a flash message" do
          expect(flash[:notice]).to eq "Your Embargo has been extended! It "\
                                       "will now expire on " \
                                       "#{Time.zone.today + 6.months}."
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
            session[:user_id] = pro_user.id
            post :create,
                 embargo_extension: { embargo_id: embargo.id,
                                      extension_duration: "3_months" }
          end
        end

        it "updates the embargo" do
          expect(embargo.reload.publish_at.to_date).to eq Time.zone.today + 6.months
        end

        it "sets a flash message" do
          expect(flash[:notice]).to eq "Your Embargo has been extended! It "\
                                       "will now expire on " \
                                       "#{Time.zone.today + 6.months}."
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
               embargo_extension: { embargo_id: embargo.id,
                                    extension_duration: "3_months" }
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when the extension is invalid" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          post :create,
               embargo_extension: { embargo_id: embargo.id }
        end
      end

      it "sets a flash error message" do
        expect(flash[:error]).to eq "Sorry, something went wrong extending " \
                                    "your embargo, please try again."
      end
    end
  end
end
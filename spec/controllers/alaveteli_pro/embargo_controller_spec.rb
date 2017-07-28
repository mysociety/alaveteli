# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::EmbargoesController do
  let(:pro_user) { FactoryGirl.create(:pro_user) }
  let(:admin) do
    user = FactoryGirl.create(:pro_admin_user)
    user.roles << Role.find_by(name: 'pro')
    user
  end
  let(:info_request) { FactoryGirl.create(:info_request, user: pro_user) }
  let(:embargo) { FactoryGirl.create(:embargo, info_request: info_request) }

  describe "#destroy" do
    context "when the user is allowed to update the embargo" do
      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            delete :destroy, id: embargo.id
          end
        end

        it "destroys the embargo" do
          expect { AlaveteliPro::Embargo.find(embargo.id) }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "because they are an admin" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            delete :destroy, id: embargo.id
          end
        end

        it "destroys the embargo" do
          expect(admin.is_pro_admin?).to be true
          expect { AlaveteliPro::Embargo.find(embargo.id) }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the user is not allowed to update the embargo" do
      let(:other_user) { FactoryGirl.create(:pro_user) }

      it "raises a CanCan::AccessDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            delete :destroy, id: embargo.id
          end
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end

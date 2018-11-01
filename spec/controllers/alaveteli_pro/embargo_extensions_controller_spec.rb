# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliPro::EmbargoExtensionsController do
  let(:pro_user) { FactoryBot.create(:pro_user) }

  let(:admin) do
    user = FactoryBot.create(:pro_admin_user)
    user.roles << Role.find_by(name: 'pro')
    user
  end

  let(:info_request) do
    # so that embargoes are near expiry
    time_travel_to(88.days.ago) do
      FactoryBot.create(:info_request, user: pro_user)
    end
  end

  let(:embargo) do
    # so that embargoes are near expiry
    time_travel_to(88.days.ago) do
      embargo = FactoryBot.create(:embargo, info_request: info_request)
      embargo.
        update_attribute(:publish_at, embargo.expiring_notification_at + 7.days)
      embargo
    end
  end

  let(:embargo_expiry) { embargo.publish_at }

  describe "#create" do

    context "when the user is allowed to update the embargo" do

      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end

        it "updates the embargo" do
          expected_date = embargo_expiry + AlaveteliPro::Embargo::THREE_MONTHS
          expect(embargo.reload.publish_at).to eq expected_date
        end

        it "sets a flash message" do
          expected_date = embargo_expiry + AlaveteliPro::Embargo::THREE_MONTHS
          expect(flash[:notice]).
            to eq "Your request will now be private until " \
                  "#{expected_date.strftime('%d %B %Y')}."
        end

        it "redirects to the request show page" do
          expect(response).
            to redirect_to show_alaveteli_pro_request_path(
              url_title: info_request.url_title)
        end

      end

      context "because they are a pro admin" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end

        it "updates the embargo" do
          expected_date = embargo_expiry + AlaveteliPro::Embargo::THREE_MONTHS
          expect(embargo.reload.publish_at).to eq expected_date
        end

        it "sets a flash message" do
          expected_date = embargo_expiry + AlaveteliPro::Embargo::THREE_MONTHS
          expect(flash[:notice]).
            to eq "Your request will now be private until " \
                  "#{expected_date.strftime('%d %B %Y')}."
        end

        it "redirects to the request show page" do
          expect(response).
            to redirect_to show_alaveteli_pro_request_path(
              url_title: info_request.url_title)
        end

      end

    end

    context "when the user does not own the embargo" do
      let(:other_user) {  FactoryBot.create(:pro_user) }

      it 'raises a CanCan::AccessDenied error' do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end.to raise_error(CanCan::AccessDenied)
      end

      context 'when the user does not have a pro account' do

        before do
          pro_user.remove_role(:pro)
        end

        it "does not allow access to the controller action" do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
            expect(response).to redirect_to frontpage_path
          end
        end

      end

    end

    context 'when the embargo is not near expiry' do

      let(:info_request) { FactoryBot.create(:info_request, user: pro_user) }
      let(:embargo) do
        FactoryBot.create(:embargo, info_request: info_request)
      end

      it "raises a PermissionDenied error if the owner requests extension" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end.to raise_error(ApplicationController::PermissionDenied)
      end

      it "raises a PermissionDenied error if an admin requests extension" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end.to raise_error(ApplicationController::PermissionDenied)
      end

    end

    context "when the info_request is part of a batch request" do
      let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

      before do
        info_request.info_request_batch = info_request_batch
        info_request.save!
      end

      it "raises a PermissionDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, params: { alaveteli_pro_embargo_extension: {
                                      embargo_id: embargo.id,
                                      extension_duration: "3_months"
                                    }
                                  }
          end
        end.to raise_error(ApplicationController::PermissionDenied)
      end
    end

    context "when the extension is invalid" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          post :create, params: { alaveteli_pro_embargo_extension: {
                                    embargo_id: embargo.id
                                  }
                                }
        end
      end

      it "sets a flash error message" do
        expect(flash[:error]).to eq "Sorry, something went wrong updating " \
                                    "your request's privacy settings, " \
                                    "please try again."
      end
    end

  end

  describe "#create_batch" do
    let(:info_request_batch) do
      batch = FactoryBot.create(
        :info_request_batch,
        embargo_duration: "3_months",
        user: pro_user,
        public_bodies: FactoryBot.create_list(:public_body, 2))
      batch.create_batch!
      batch
    end

    context "when the user is allowed to update the embargo" do
      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create_batch, params: {
                                  info_request_batch_id: info_request_batch.id,
                                  extension_duration: "3_months"
                                }
          end
        end

        it "extends every embargo in the batch" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.embargo.reload.publish_at).
              to eq AlaveteliPro::Embargo.six_months_from_now
          end
        end

        it "redirects to the batch page" do
          expected_path = show_alaveteli_pro_batch_request_path(
            info_request_batch)
          expect(response).to redirect_to expected_path
        end

        it "sets a flash message" do
          six_months_from_now = AlaveteliPro::Embargo.six_months_from_now
          expiry_date = "#{six_months_from_now.strftime('%d %B %Y')}"
          expected_message = "Your requests will now be private " \
                             "until #{expiry_date}."
          expect(flash[:notice]).to eq expected_message
        end
      end

      context "because they are an admin" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :create_batch, params: {
                                  info_request_batch_id: info_request_batch.id,
                                  extension_duration: "3_months"
                                }
          end
        end

        it "extends every embargo in the batch" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.embargo.reload.publish_at).
              to eq AlaveteliPro::Embargo.six_months_from_now
          end
        end

        it "redirects to the batch page" do
          expected_path = show_alaveteli_pro_batch_request_path(
            info_request_batch)
          expect(response).to redirect_to expected_path
        end

        it "sets a flash message" do
          six_months_from_now = AlaveteliPro::Embargo.six_months_from_now
          expiry_date = "#{six_months_from_now.strftime('%d %B %Y')}"
          expected_message = "Your requests will now be private " \
                             "until #{expiry_date}."
          expect(flash[:notice]).to eq expected_message
        end
      end
    end

    context 'when the user is not allowed to update the embargo' do
      let(:other_user) { FactoryBot.create(:pro_user) }

      it 'raises a CanCan::AccessDenied error' do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            post :create_batch, params: {
                                  info_request_batch_id: info_request_batch.id,
                                  extension_duration: "3_months"
                                }
          end
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when the extension is invalid" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          post :create_batch, params: {
                                info_request_batch_id: info_request_batch.id
                              }
        end
      end

      it "sets a flash error message" do
        expect(flash[:error]).to eq "Sorry, something went wrong updating " \
                                    "your requests' privacy settings, " \
                                    "please try again."
      end
    end

    context "when an info_request_id is supplied" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = admin.id
          post :create_batch,
               params: {
                 info_request_batch_id: info_request_batch.id,
                 info_request_id: info_request_batch.info_requests.first.id
               }
        end
      end

      it "redirects to that request, not the batch" do
        expected_path = show_alaveteli_pro_request_path(
            url_title: info_request_batch.info_requests.first.url_title)
          expect(response).to redirect_to(expected_path)
      end
    end
  end
end

# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::EmbargoesController do
  let(:pro_user) { FactoryBot.create(:pro_user) }

  let(:admin) do
    user = FactoryBot.create(:pro_admin_user)
    user.roles << Role.find_by(name: 'pro')
    user
  end
  let(:info_request) { FactoryBot.create(:info_request, user: pro_user) }
  let(:embargo) { FactoryBot.create(:embargo, info_request: info_request) }

  describe '#create' do
    let(:info_request) { FactoryBot.create(:info_request, user: pro_user) }

    context 'when the user is allowed to add an embargo' do

      context 'because they are the owner' do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, { alaveteli_pro_embargo: {
                            info_request_id: info_request,
                            embargo_duration: '3_months' }
                          }
          end
        end

        it 'creates the embargo' do
          expect(info_request.reload.embargo).to be_a(AlaveteliPro::Embargo)
        end

        it 'sets the expected duration' do
          expect(info_request.reload.embargo.embargo_duration).to eq('3_months')
        end

      end

      context 'because they are a pro admin' do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :create, { alaveteli_pro_embargo: {
                            info_request_id: info_request,
                            embargo_duration: '3_months' }
                          }
          end
        end

        it 'creates the embargo' do
          expect(info_request.reload.embargo).to be_a(AlaveteliPro::Embargo)
        end

        it 'sets the expected duration' do
          expect(info_request.reload.embargo.embargo_duration).to eq('3_months')
        end

      end

    end

    context "when the user is not allowed to update the embargo" do
      let(:other_user) { FactoryBot.create(:pro_user) }

      it "raises a CanCan::AccessDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            post :create, { alaveteli_pro_embargo: {
                            info_request_id: info_request,
                            embargo_duration: '3_months' }
                          }
          end
        end.to raise_error(CanCan::AccessDenied)
      end

    end

    context "when the info_request is part of a batch request" do
      let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

      before do
        info_request.info_request_batch = info_request_batch
        info_request.save!
      end

      it "raises a CanCan::AccessDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :create, { alaveteli_pro_embargo: {
                            info_request_id: info_request,
                            embargo_duration: '3_months' }
                          }
          end
        end.to raise_error(CanCan::AccessDenied)
      end

    end

  end

  describe "#destroy" do
    context "when the user is allowed to remove the embargo" do
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

        it "logs an 'expire_embargo' event" do
          expect(info_request.reload.info_request_events.last.event_type).
            to eq 'expire_embargo'
        end

        context 'they no longer have pro status' do

          before do
            pro_user.remove_role(:pro)
          end

          it 'destroys the embargo' do
            expect { AlaveteliPro::Embargo.find(embargo.id) }.
              to raise_error(ActiveRecord::RecordNotFound)
          end

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

        it "logs an 'expire_embargo' event" do
          expect(info_request.reload.info_request_events.last.event_type).
            to eq 'expire_embargo'
        end

      end
    end

    context "when the user is not allowed to update the embargo" do
      let(:other_user) { FactoryBot.create(:pro_user) }

      it "raises a CanCan::AccessDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            delete :destroy, id: embargo.id
          end
        end.to raise_error(CanCan::AccessDenied)
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
            delete :destroy, id: embargo.id
          end
        end.to raise_error(ApplicationController::PermissionDenied)
      end
    end
  end

  describe "#destroy_batch" do
    let(:info_request_batch) do
      batch = FactoryBot.create(
        :info_request_batch,
        embargo_duration: "3_months",
        user: pro_user,
        public_bodies: FactoryBot.create_list(:public_body, 2))
      batch.create_batch!
      batch
    end

    context "when the user is allowed to update the batch" do
      context "because they are the owner" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = pro_user.id
            post :destroy_batch, info_request_batch_id: info_request_batch.id
          end
        end

        it "destroys all the embargoes" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.reload.embargo).to be_nil
          end
        end

        it "sets embargo_duration to nil on the batch" do
          expect(info_request_batch.reload.embargo_duration).to be_nil
        end

        it "logs an 'expire_embargo' event for each request in the batch" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.info_request_events.last.event_type).
              to eq 'expire_embargo'
          end
        end

        it "shows a flash message" do
          expected_message = "Your requests are now public!"
          expect(flash[:notice]).to eq expected_message
        end

        it "redirects to the batch request page" do
          expected_path = show_alaveteli_pro_batch_request_path(
            info_request_batch)
          expect(response).to redirect_to(expected_path)
        end
      end

      context "because they are an admin" do
        before do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = admin.id
            post :destroy_batch, info_request_batch_id: info_request_batch.id
          end
        end

        it "destroys all the embargoes" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.reload.embargo).to be_nil
          end
        end

        it "sets embargo_duration to nil on the batch" do
          expect(info_request_batch.reload.embargo_duration).to be_nil
        end

        it "logs an 'expire_embargo' event for each request in the batch" do
          info_request_batch.info_requests.each do |info_request|
            expect(info_request.info_request_events.last.event_type).
              to eq 'expire_embargo'
          end
        end

        it "shows a flash message" do
          expected_message = "Your requests are now public!"
          expect(flash[:notice]).to eq expected_message
        end

        it "redirects to the batch request page" do
          expected_path = show_alaveteli_pro_batch_request_path(
            info_request_batch)
          expect(response).to redirect_to(expected_path)
        end
      end
    end

    context "when the user is not allowed to update the batch" do
      let(:other_user) { FactoryBot.create(:pro_user) }

      it "raises a CanCan::AccessDenied error" do
        expect do
          with_feature_enabled(:alaveteli_pro) do
            session[:user_id] = other_user.id
            post :destroy_batch, info_request_batch_id: info_request_batch.id
          end
        end.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when an info_request_id is supplied" do
      before do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = admin.id
          post :destroy_batch,
               info_request_batch_id: info_request_batch.id,
               info_request_id: info_request_batch.info_requests.first.id
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

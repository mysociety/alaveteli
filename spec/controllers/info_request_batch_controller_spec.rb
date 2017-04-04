# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequestBatchController do
  describe "#show" do
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }
    let(:bodies) { [first_public_body, second_public_body] }
    let!(:info_request_batch) do
      FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                              :body => 'Matched body',
                                              :public_bodies => bodies)
    end
    let(:params) { {:id => info_request_batch.id} }
    let(:action) { get :show, params }
    let(:pro_user) { FactoryGirl.create(:pro_user) }

    it 'should be successful' do
      action
      expect(response).to be_success
    end

    it 'should assign an info_request_batch to the view' do
      action
      expect(assigns[:info_request_batch]).to eq(info_request_batch)
    end

    context 'when the batch has not been sent' do
      it 'should assign public_bodies to the view' do
        action
        expect(assigns[:public_bodies]).to eq(bodies)
      end
    end

    context 'when the batch has been sent' do
      let!(:first_request) do
        FactoryGirl.create(:info_request, :info_request_batch => info_request_batch,
                                          :public_body => first_public_body)
      end
      let!(:second_request) do
        FactoryGirl.create(:info_request, :info_request_batch => info_request_batch,
                                          :public_body => second_public_body)
      end

      before do
        info_request_batch.sent_at = Time.zone.now
        info_request_batch.save!
      end

      it 'should assign info_requests to the view' do
        action
        expect(assigns[:info_requests].sort).to eq([first_request, second_request])
      end
    end

    describe 'when params[:pro] is true' do
      before do
        params[:pro] = "1"
        session[:user_id] = pro_user.id
      end

      it "should set @in_pro_area to true" do
        with_feature_enabled(:alaveteli_pro) do
          action
          expect(assigns[:in_pro_area]).to be true
        end
      end
    end

    describe "redirecting embargoed requests" do
      context "when showing pros their own requests" do
        context "when the request is embargoed" do
          let(:batch) do
            FactoryGirl.create(:embargoed_batch_request, public_bodies: bodies,
                                                         user: pro_user)
          end

          it "should redirect to the pro version of the page" do
            with_feature_enabled(:alaveteli_pro) do
              session[:user_id] = pro_user
              get :show, id: batch.id
              expected_url = show_alaveteli_pro_batch_request_path(batch)
              expect(response).to redirect_to expected_url
            end
          end
        end

        context "when the request is not embargoed" do
          let(:batch) do
            FactoryGirl.create(:batch_request, user: pro_user,
                                               public_bodies: bodies)
          end

          it "should not redirect to the pro version of the page" do
            with_feature_enabled(:alaveteli_pro) do
              session[:user_id] = pro_user
              get :show, id: batch.id
              expect(response).to be_success
            end
          end
        end
      end

      context "when showing pros someone else's request" do
        before do
          session[:user_id] = pro_user
        end

        it "should not redirect to the pro version of the page" do
          with_feature_enabled(:alaveteli_pro) do
            get :show, id: info_request_batch.id
            expect(response).to be_success
          end
        end
      end
    end

    describe "accessing embargoed batches" do
      let(:batch) do
        FactoryGirl.create(:embargoed_batch_request, public_bodies: bodies,
                                                     user: pro_user)
      end
      let(:admin) { FactoryGirl.create(:admin_user) }
      let(:pro_admin) { FactoryGirl.create(:pro_admin_user) }
      let(:other_pro_user) { FactoryGirl.create(:pro_user) }
      let(:other_user) { FactoryGirl.create(:user) }

      it "allows the owner to access it" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_user.id
          get :show, id: batch.id, pro: "1"
          expect(response).to be_success
        end
      end

      it "allows pro admins to access it" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = pro_admin.id
          get :show, id: batch.id
          expect(response).to be_success
        end
      end

      it "raises an ActiveRecord::RecordNotFound error for admins" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = admin.id
          expect { get :show, id: batch.id }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it "raises an ActiveRecord::RecordNotFound error for other pro users" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = other_pro_user.id
          expect { get :show, id: batch.id }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it "raises an ActiveRecord::RecordNotFound error for normal users" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = other_user.id
          expect { get :show, id: batch.id }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it "raises an ActiveRecord::RecordNotFound error for anon users" do
        with_feature_enabled(:alaveteli_pro) do
          session[:user_id] = nil
          expect { get :show, id: batch.id }.
            to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end

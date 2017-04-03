# -*- encoding : utf-8 -*-
require 'spec_helper'

describe InfoRequestBatchController do
  describe "#show" do
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }
    let!(:info_request_batch) do
      FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                              :body => 'Matched body',
                                              :public_bodies => [first_public_body,
                                                                 second_public_body])
    end
    let(:params) { {:id => info_request_batch.id} }
    let(:action) { get :show, params }

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
        expect(assigns[:public_bodies]).to eq([first_public_body, second_public_body])
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
      let(:pro_user) { FactoryGirl.create(:pro_user) }

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
  end
end

# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestBatchController, "when showing a request" do

    before do
        @info_request_batch = FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                                                      :body => 'Matched body')
        @first_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch)
        @second_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch)
        @default_params = {:id => @info_request_batch.id}
    end

    def make_request(params=@default_params)
        get :show, params
    end

    it 'should be successful' do
        make_request
        response.should be_success
    end

    it 'should assign info_requests to the view' do
        make_request
        assigns[:info_requests].should == [@first_request, @second_request]
    end

    it 'should assign an info_request_batch to the view' do
        make_request
        assigns[:info_request_batch].should == @info_request_batch
    end
end

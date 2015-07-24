# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestBatchController, "when showing a request" do

  before do
    @first_public_body = FactoryGirl.create(:public_body)
    @second_public_body = FactoryGirl.create(:public_body)
    @info_request_batch = FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                             :body => 'Matched body',
                                             :public_bodies => [@first_public_body,
                                                                @second_public_body])
    @first_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch,
                                        :public_body => @first_public_body)
    @second_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch,
                                         :public_body => @second_public_body)
    @default_params = {:id => @info_request_batch.id}
  end

  def make_request(params=@default_params)
    get :show, params
  end

  it 'should be successful' do
    make_request
    response.should be_success
  end

  it 'should assign an info_request_batch to the view' do
    make_request
    assigns[:info_request_batch].should == @info_request_batch
  end

  context 'when the batch has not been sent' do

    it 'should assign public_bodies to the view' do
      make_request
      assigns[:public_bodies].should == [@first_public_body, @second_public_body]
    end
  end

  context 'when the batch has been sent' do

    it 'should assign info_requests to the view' do
      @info_request_batch.sent_at = Time.now
      @info_request_batch.save!
      make_request
      assigns[:info_requests].sort.should == [@first_request, @second_request]
    end

  end

end

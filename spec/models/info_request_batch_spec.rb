require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequestBatch, "when validating" do

    before do
        @info_request_batch = FactoryGirl.build(:info_request_batch)
    end

    it 'should require a user' do
        @info_request_batch.user = nil
        @info_request_batch.valid?.should be_false
        @info_request_batch.errors.full_messages.should == ["User can't be blank"]
    end

    it 'should require a title' do
        @info_request_batch.title = nil
        @info_request_batch.valid?.should be_false
        @info_request_batch.errors.full_messages.should == ["Title can't be blank"]
    end

end

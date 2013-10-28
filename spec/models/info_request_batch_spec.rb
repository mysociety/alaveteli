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

    it 'should require a body' do
        @info_request_batch.body = nil
        @info_request_batch.valid?.should be_false
        @info_request_batch.errors.full_messages.should == ["Body can't be blank"]
    end

end

describe InfoRequestBatch, "when finding an existing batch" do

    before do
        @info_request_batch = FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                                                      :body => 'Matched body')
        @first_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch)
        @second_request = FactoryGirl.create(:info_request, :info_request_batch => @info_request_batch)
    end

    it 'should return a batch with the same user, title and body sent to one of the same public bodies' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [@first_request.public_body_id]).should_not be_nil
    end

    it 'should not return a batch with the same title and body sent to another public body' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [FactoryGirl.create(:public_body).id]).should be_nil
    end

    it 'should not return a batch sent the same public bodies with a different title and body' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       'Other title',
                                       'Other body',
                                       [@first_request.public_body_id]).should be_nil
    end

    it 'should not return a batch sent to one of the same public bodies with the same title and body by
        a different user' do
        InfoRequestBatch.find_existing(FactoryGirl.create(:user),
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [@first_request.public_body_id]).should be_nil
    end
end

describe InfoRequestBatch, "when creating a batch", :focus => true do

    it 'should substitute authority name for the placeholder in each request' do
        info_request_params = {:title => 'A test title'}
        outgoing_message_params = {:body => "Dear [Authority name],\nA message\nYours faithfully,\nRequester",
                                  }
        first_public_body = FactoryGirl.create(:public_body)
        second_public_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        results = InfoRequestBatch.create_batch!(info_request_params,
                                                 outgoing_message_params,
                                                 [first_public_body.id, second_public_body.id],
                                                 user)
        info_requests = results[:batch].info_requests
        [first_public_body, second_public_body].each do |public_body|
            request = info_requests.detect{|info_request| info_request.public_body == public_body}
            request.outgoing_messages.first.body.should == "Dear #{public_body.name},\nA message\nYours faithfully,\nRequester"
        end
    end

end

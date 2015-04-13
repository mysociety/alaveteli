# == Schema Information
#
# Table name: info_request_batches
#
#  id         :integer          not null, primary key
#  title      :text             not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  body       :text
#  sent_at    :datetime
#

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
        @first_body = FactoryGirl.create(:public_body)
        @second_body = FactoryGirl.create(:public_body)
        @info_request_batch = FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                                                      :body => 'Matched body',
                                                                      :public_bodies => [@first_body,
                                                                                         @second_body])
    end

    it 'should return a batch with the same user, title and body sent to one of the same public bodies' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [@first_body]).should_not be_nil
    end

    it 'should not return a batch with the same title and body sent to another public body' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [FactoryGirl.create(:public_body)]).should be_nil
    end

    it 'should not return a batch sent the same public bodies with a different title and body' do
        InfoRequestBatch.find_existing(@info_request_batch.user,
                                       'Other title',
                                       'Other body',
                                       [@first_body]).should be_nil
    end

    it 'should not return a batch sent to one of the same public bodies with the same title and body by
        a different user' do
        InfoRequestBatch.find_existing(FactoryGirl.create(:user),
                                       @info_request_batch.title,
                                       @info_request_batch.body,
                                       [@first_body]).should be_nil
    end
end

describe InfoRequestBatch, "when creating a batch" do

    before do
        @title = 'A test title'
        @body = "Dear [Authority name],\nA message\nYours faithfully,\nRequester"
        @first_public_body = FactoryGirl.create(:public_body)
        @second_public_body = FactoryGirl.create(:public_body)
        @user = FactoryGirl.create(:user)
        @info_request_batch = InfoRequestBatch.create!({:title => @title,
                                                       :body => @body,
                                                       :public_bodies => [@first_public_body,
                                                                          @second_public_body],
                                                       :user => @user})
    end

    it 'should substitute authority name for the placeholder in each request' do
        unrequestable = @info_request_batch.create_batch!
        [@first_public_body, @second_public_body].each do |public_body|
            request = @info_request_batch.info_requests.detect do |info_request|
                info_request.public_body == public_body
            end
            expected = "Dear #{public_body.name},\nA message\nYours faithfully,\nRequester"
            request.outgoing_messages.first.body.should == expected
        end
    end

    it 'should send requests to requestable public bodies, and return a list of unrequestable ones' do
        @first_public_body.stub(:is_requestable?).and_return(false)
        unrequestable = @info_request_batch.create_batch!
        unrequestable.should == [@first_public_body]
        @info_request_batch.info_requests.size.should == 1
        request = @info_request_batch.info_requests.first
        request.outgoing_messages.first.status.should == 'sent'
    end

    it 'should set the sent_at value of the info request batch' do
        @info_request_batch.create_batch!
        @info_request_batch.sent_at.should_not be_nil
    end

end

describe InfoRequestBatch, "when sending batches" do

    before do
        @title = 'A test title'
        @body = "Dear [Authority name],\nA message\nYours faithfully,\nRequester"
        @first_public_body = FactoryGirl.create(:public_body)
        @second_public_body = FactoryGirl.create(:public_body)
        @user = FactoryGirl.create(:user)
        @info_request_batch = InfoRequestBatch.create!({:title => @title,
                                                       :body => @body,
                                                       :public_bodies => [@first_public_body,
                                                                          @second_public_body],
                                                       :user => @user})
        @sent_batch = InfoRequestBatch.create!({:title => @title,
                                                :body => @body,
                                                :public_bodies => [@first_public_body,
                                                                   @second_public_body],
                                                :user => @user,
                                                :sent_at => Time.now})
    end

    it 'should send requests and notifications for only unsent batch requests' do
        InfoRequestBatch.send_batches
        ActionMailer::Base.deliveries.size.should == 3
        first_email = ActionMailer::Base.deliveries.first
        first_email.to.should == [@first_public_body.request_email]
        first_email.subject.should == 'Freedom of Information request - A test title'

        second_email = ActionMailer::Base.deliveries.second
        second_email.to.should == [@second_public_body.request_email]
        second_email.subject.should == 'Freedom of Information request - A test title'

        third_email = ActionMailer::Base.deliveries.third
        third_email.to.should == [@user.email]
        third_email.subject.should == 'Your batch request "A test title" has been sent'
    end

end


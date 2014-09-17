require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe HealthChecks::Checks::OutgoingMessageCheck do
    include HealthChecks::Checks

    it { should be_kind_of(HealthChecks::HealthCheckable) }

    before(:each) do
        @check = HealthChecks::Checks::OutgoingMessageCheck.new
    end

    describe :check do

        it 'is successful if the last incoming message was created in the last day' do
            FactoryGirl.create(:info_request)
            expect(@check.check).to be_true
        end

        it 'fails if the last incoming message was created over a day ago' do
            params = { :status => 'ready',
                       :message_type => 'followup',
                       :body => 'I want a review',
                       :what_doing => 'internal_review',
                       :info_request => FactoryGirl.create(:info_request),
                       :created_at => 30.days.ago }
            FactoryGirl.create(:outgoing_message, params)
            expect(@check.check).to be_false
        end

    end
 
end
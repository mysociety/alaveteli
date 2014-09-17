require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe HealthChecks::Checks::IncomingMessageCheck do
    include HealthChecks::Checks

    it { should be_kind_of(HealthChecks::HealthCheckable) }

    before(:each) do
        @check = HealthChecks::Checks::IncomingMessageCheck.new
    end

    describe :check do

        it 'is successful if the last incoming message was created in the last day' do
            FactoryGirl.create(:incoming_message)
            expect(@check.check).to be_true
        end

        it 'fails if the last incoming message was created over a day ago' do
            FactoryGirl.create(:incoming_message, :created_at => 28.days.ago)
            expect(@check.check).to be_false
        end

    end
 
end
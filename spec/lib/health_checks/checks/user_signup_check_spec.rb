require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe HealthChecks::Checks::UserSignupCheck do
    include HealthChecks::Checks

    it { should be_kind_of(HealthChecks::HealthCheckable) }

    before(:each) do
        @check = HealthChecks::Checks::UserSignupCheck.new
    end

    describe :check do

        it 'is successful if the last user was created in the last day' do
            FactoryGirl.create(:user)
            expect(@check.check).to be_true
        end

        it 'fails if the last user was created over a day ago' do
            FactoryGirl.create(:user, :created_at => 28.days.ago)
            expect(@check.check).to be_false
        end

    end
 
end
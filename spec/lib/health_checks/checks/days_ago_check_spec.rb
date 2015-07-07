# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe HealthChecks::Checks::DaysAgoCheck do
    include HealthChecks::Checks

    it { should be_kind_of(HealthChecks::HealthCheckable) }

    it 'defaults to comparing to one day ago' do
        check = HealthChecks::Checks::DaysAgoCheck.new
        expect(check.days).to eq(1)
    end

    it 'accepts a custom number of days' do
        check = HealthChecks::Checks::DaysAgoCheck.new(:days => 4)
        expect(check.days).to eq(4)
    end

    describe :ok? do

        it 'is successful if the subject is in the last day' do
            check = HealthChecks::Checks::DaysAgoCheck.new { Time.now }
            expect(check.ok?).to be_true
        end

        it 'fails if the subject is over a day ago' do
            check = HealthChecks::Checks::DaysAgoCheck.new { 2.days.ago }
            expect(check.ok?).to be_false
        end

    end

    describe :failure_message do

        it 'includes the check subject in the default message' do
            subject = 2.days.ago
            check = HealthChecks::Checks::DaysAgoCheck.new { subject }
            expect(check.failure_message).to include(subject.to_s)
        end

        it 'includes the check subject in a custom message' do
            params = { :failure_message => 'This check failed' }
            subject = 2.days.ago
            check = HealthChecks::Checks::DaysAgoCheck.new(params) { subject }
            expect(check.failure_message).to include(subject.to_s)
        end

    end

    describe :success_message do

        it 'includes the check subject in the default message' do
            subject = Time.now
            check = HealthChecks::Checks::DaysAgoCheck.new { subject }
            expect(check.failure_message).to include(subject.to_s)
        end

        it 'includes the check subject in a custom message' do
            params = { :success_message => 'This check succeeded' }
            subject = Time.now
            check = HealthChecks::Checks::DaysAgoCheck.new(params) { subject }
            expect(check.success_message).to include(subject.to_s)
        end

    end

end

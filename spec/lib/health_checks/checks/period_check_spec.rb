require 'spec_helper'

RSpec.describe HealthChecks::Checks::PeriodCheck do
  include HealthChecks::Checks

  it { is_expected.to be_kind_of(HealthChecks::HealthCheckable) }

  it 'defaults to period to one day' do
    check = HealthChecks::Checks::PeriodCheck.new
    expect(check.period).to eq(1.day)
  end

  it 'accepts a custom period' do
    check = HealthChecks::Checks::PeriodCheck.new(period: 4.days)
    expect(check.period).to eq(4.days)
  end

  describe :ok? do

    it 'is successful if the subject is in the last day' do
      check = HealthChecks::Checks::PeriodCheck.new { Time.zone.now }
      expect(check.ok?).to be true
    end

    it 'fails if the subject is over a day ago' do
      check = HealthChecks::Checks::PeriodCheck.new { 2.days.ago }
      expect(check.ok?).to be false
    end

  end

  describe :failure_message do

    it 'includes the check subject in the default message' do
      subject = 2.days.ago
      check = HealthChecks::Checks::PeriodCheck.new { subject }
      expect(check.failure_message).to include(subject.to_s)
    end

    it 'includes the check subject in a custom message' do
      params = { :failure_message => 'This check failed' }
      subject = 2.days.ago
      check = HealthChecks::Checks::PeriodCheck.new(params) { subject }
      expect(check.failure_message).to include(subject.to_s)
    end

  end

  describe :success_message do

    it 'includes the check subject in the default message' do
      subject = Time.zone.now
      check = HealthChecks::Checks::PeriodCheck.new { subject }
      expect(check.failure_message).to include(subject.to_s)
    end

    it 'includes the check subject in a custom message' do
      params = { :success_message => 'This check succeeded' }
      subject = Time.zone.now
      check = HealthChecks::Checks::PeriodCheck.new(params) { subject }
      expect(check.success_message).to include(subject.to_s)
    end

  end

end

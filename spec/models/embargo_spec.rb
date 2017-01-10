# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: embargoes
#
#  id               :integer          not null, primary key
#  info_request_id  :integer
#  publish_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string(255)
#

require 'spec_helper'

describe Embargo, :type => :model do
  let(:embargo) { FactoryGirl.create(:embargo) }

  it 'belongs to an info_request' do
    expect(embargo.info_request).not_to be_nil
  end

  it 'has a publish_at field' do
    expect(embargo.publish_at).to be_a(ActiveSupport::TimeWithZone)
  end

  it 'requires a publish_at field' do
    embargo.publish_at = nil
    expect(embargo).not_to be_valid
  end

  it 'has an embargo_duration field' do
    expect(embargo.embargo_duration).to be_a(String)
  end

  it 'validates embargo_duration field is in list' do
    embargo.allowed_durations.each do |duration|
      embargo.embargo_duration = duration
      expect(embargo).to be_valid
    end
    embargo.embargo_duration = "not_in_list"
    expect(embargo).not_to be_valid
  end

  it 'allows embargo_duration to be nil' do
    embargo.embargo_duration = nil
    expect(embargo).to be_valid
  end

  describe 'setting publish_at' do
    let(:info_request) { FactoryGirl.create(:info_request) }

    it 'sets publish_at from duration during creation' do
      embargo = Embargo.create(info_request: info_request,
                               embargo_duration: "3_months")
      expect(embargo.publish_at).to eq (Time.zone.now + 3.months).beginning_of_day
    end

    it 'doesnt set publish_at from duration if its already set' do
      embargo = Embargo.create(info_request: info_request,
                               publish_at: Time.zone.today,
                               embargo_duration: "3_months")
      expect(embargo.publish_at).to eq Time.zone.today
    end
  end

  describe 'extending' do
    let(:embargo_extension) { FactoryGirl.create(:embargo_extension) }
    let(:embargo) { embargo_extension.embargo }

    it 'allows extending the embargo' do
      old_publish_at = embargo.publish_at
      expect(old_publish_at).to eq (Time.zone.now + 3.months).beginning_of_day
      embargo.extend(embargo_extension)
      expected_publish_at = old_publish_at + 3.months
      expect(embargo.publish_at).to eq expected_publish_at
    end
  end

  describe 'expiring scope' do

    it 'includes embargoes expiring in less than a week' do
      embargo = FactoryGirl.create(:embargo, :publish_at => Time.now + 6.days)
      expect(Embargo.expiring.include?(embargo)).to be true
    end

    it 'excludes embargoes expiring in more than a week' do
      embargo = FactoryGirl.create(:embargo, :publish_at => Time.now + 8.days)
      expect(Embargo.expiring.include?(embargo)).to be false
    end

  end
end

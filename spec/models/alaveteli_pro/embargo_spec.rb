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

describe AlaveteliPro::Embargo, :type => :model do
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

  it 'has an embargo duration of three months by default' do
    expect(AlaveteliPro::Embargo.new.embargo_duration).to eq "3_months"
  end

  it 'allows the embargo duration to be set' do
    expect(AlaveteliPro::Embargo.new(embargo_duration: "6_months").
      embargo_duration).to eq "6_months"
  end

  describe 'setting publish_at' do
    let(:info_request) { FactoryGirl.create(:info_request) }

    it 'sets publish_at from duration during creation' do
      embargo = AlaveteliPro::Embargo.create(info_request: info_request,
                               embargo_duration: "3_months")
      expect(embargo.publish_at).to eq AlaveteliPro::Embargo.three_months_from_now
    end

    it "doesn't set publish_at from duration if its already set" do
      embargo = AlaveteliPro::Embargo.create(info_request: info_request,
                               publish_at: Time.zone.now.beginning_of_day,
                               embargo_duration: "3_months")
      expect(embargo.publish_at).to eq Time.zone.today
    end
  end

  describe 'setting expiring_notification_at' do
    let(:info_request) { FactoryGirl.create(:info_request) }

    it 'sets expiring_notification_at from publish_at during creation' do
      embargo = AlaveteliPro::Embargo.create(info_request: info_request,
                                             embargo_duration: "3_months")
      expect(embargo).to be_valid
      expect(embargo.persisted?).to be true
      expected = AlaveteliPro::Embargo.three_months_from_now - 1.week
      expect(embargo.expiring_notification_at).to eq expected
    end

    it "doesn't set expiring_notification_at if it's already set" do
      embargo = AlaveteliPro::Embargo.create(
        info_request: info_request,
        embargo_duration: "3_months",
        expiring_notification_at: Time.zone.now.beginning_of_day)
      expect(embargo.expiring_notification_at).to eq Time.zone.today
    end
  end

  describe 'saving' do
    let(:embargo_extension) { FactoryGirl.create(:embargo_extension) }
    let(:embargo) { embargo_extension.embargo }

    it 'records an "set_embargo" event on the request' do
      latest_event = embargo.info_request.info_request_events.last
      expect(latest_event.event_type).to eq 'set_embargo'
      expect(latest_event.params[:embargo_id]).
        to eq embargo.id
      expect(latest_event.params[:embargo_extension_id]).
        to be_nil
    end

  end

  describe 'extending' do
    let(:embargo_extension) { FactoryGirl.create(:embargo_extension) }
    let(:embargo) { embargo_extension.embargo }

    it 'allows extending the embargo' do
      old_publish_at = embargo.publish_at
      expect(old_publish_at).to eq AlaveteliPro::Embargo.three_months_from_now
      embargo.extend(embargo_extension)
      expect(embargo.publish_at).to eq AlaveteliPro::Embargo.six_months_from_now
    end

    it 'records an "set_embargo" event on the request' do
      embargo.extend(embargo_extension)
      latest_event = embargo.info_request.info_request_events.last
      expect(latest_event.event_type).to eq 'set_embargo'
      expect(latest_event.params[:embargo_extension_id]).
        to eq embargo_extension.id
    end

    it 'updates the expiring_notification_at date' do
      expected = AlaveteliPro::Embargo.three_months_from_now - 1.week
      expect(embargo.expiring_notification_at).to eq expected
      embargo.extend(embargo_extension)
      expected = AlaveteliPro::Embargo.six_months_from_now - 1.week
      expect(embargo.expiring_notification_at).to eq expected
    end
  end

  describe 'expiring scope' do

    it 'includes embargoes expiring in less than a week' do
      embargo = FactoryGirl.create(:embargo, :publish_at => Time.now + 6.days)
      expect(AlaveteliPro::Embargo.expiring.include?(embargo)).to be true
    end

    it 'excludes embargoes expiring in more than a week' do
      embargo = FactoryGirl.create(:embargo, :publish_at => Time.now + 8.days)
      expect(AlaveteliPro::Embargo.expiring.include?(embargo)).to be false
    end

  end

  describe '.expire_publishable' do

    context 'for an embargo whose publish_at date has passed' do
      it 'deletes the embargo' do
        embargo = FactoryGirl.create(:embargo)
        info_request = embargo.info_request
        time_travel_to(Time.zone.today + 4.months) do
          AlaveteliPro::Embargo.expire_publishable
          info_request = InfoRequest.find(info_request.id)
          expect(info_request.embargo).to be_nil
        end
      end

      it 'logs the embargo expiry' do
        embargo = FactoryGirl.create(:embargo)
        info_request = embargo.info_request
        time_travel_to(Time.zone.today + 4.months) do
          AlaveteliPro::Embargo.expire_publishable
          info_request = InfoRequest.find(info_request.id)
          expiry_events = info_request.
                            info_request_events.
                              where(:event_type => 'expire_embargo')
          expect(expiry_events.size).to eq 1
        end
      end
    end

    context 'for an embargo whose publish_at date is today' do
      it 'does not expire the embargo' do
        embargo = FactoryGirl.create(:embargo)
        info_request = embargo.info_request
        time_travel_to(AlaveteliPro::Embargo.three_months_from_now) do
          AlaveteliPro::Embargo.expire_publishable
          info_request = InfoRequest.find(info_request.id)
          expect(info_request.embargo).not_to be_nil
        end
      end
    end

  end

  describe '.three_months_from_now' do

    it 'returns midnight 91 days from now' do
      expect(AlaveteliPro::Embargo.three_months_from_now).
        to eq(Time.zone.now.beginning_of_day + 91.days)
    end

  end

  describe '.six_months_from_now' do

    it 'returns midnight 182 days from now' do
      expect(AlaveteliPro::Embargo.six_months_from_now).
        to eq(Time.zone.now.beginning_of_day + 182.days)
    end

  end

  describe '.twelve_months_from_now' do

    it 'returns midnight 364 days from now' do
      expect(AlaveteliPro::Embargo.twelve_months_from_now).
        to eq(Time.zone.now.beginning_of_day + 364.days)
    end

  end

  describe '#calculate_expiring_notification_at' do
    let(:embargo) { FactoryGirl.create(:embargo) }

    it "returns a date 1 week less than the publish_at" do
      expected = embargo.publish_at - 1.week
      expect(embargo.calculate_expiring_notification_at).to eq expected
    end
  end
end

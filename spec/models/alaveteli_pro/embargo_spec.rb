# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: embargoes
#
#  id                       :integer          not null, primary key
#  info_request_id          :integer
#  publish_at               :datetime         not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  embargo_duration         :string
#  expiring_notification_at :datetime
#

require 'spec_helper'

describe AlaveteliPro::Embargo, :type => :model do
  let(:embargo) { FactoryBot.create(:embargo) }

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
    let(:info_request) { FactoryBot.create(:info_request) }

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
    let(:info_request) { FactoryBot.create(:info_request) }

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
    let(:embargo_extension) { FactoryBot.create(:embargo_extension) }
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
    let(:embargo_extension) { FactoryBot.create(:embargo_extension) }
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
      embargo = FactoryBot.create(:embargo, :publish_at => Time.now + 6.days)
      expect(AlaveteliPro::Embargo.expiring.include?(embargo)).to be true
    end

    it 'excludes embargoes expiring in more than a week' do
      embargo = FactoryBot.create(:embargo, :publish_at => Time.now + 8.days)
      expect(AlaveteliPro::Embargo.expiring.include?(embargo)).to be false
    end

  end

  describe '#expiring_soon?' do

    it 'returns true if the embargo expires in less than a week' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now + 6.days)
      expect(embargo.expiring_soon?).to be true
    end

    it 'returns true if the embargo expires in a week' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now + 7.days)
      expect(embargo.expiring_soon?).to be true
    end

    it 'returns false if the embargo expires in more than a week' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now + 8.days)
      expect(embargo.expiring_soon?).to be false
    end

    it 'returns false if the embargo has already expired' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now.beginning_of_day)
      expect(embargo.expiring_soon?).to be false
    end

  end

  describe '#expired?' do

    it 'returns false if the publication date is in the future' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now + 1.day)
      expect(embargo.expired?).to be false
    end

    it 'returns true if the publication date is in the past' do
      embargo = FactoryBot.build(:embargo,
                                 :publish_at => Time.zone.now - 1.day)
      expect(embargo.expired?).to be true
    end

    it 'returns true on the publication date' do
      embargo = FactoryBot.build(:embargo, :publish_at => Time.zone.now)
      expect(embargo.expired?).to be true
    end

  end

  describe '.expire_publishable' do

    shared_examples_for 'successful_expiry' do

      it 'deletes the embargo' do
        AlaveteliPro::Embargo.expire_publishable
        expect(info_request.reload.embargo).to be_nil
      end

      it 'logs the embargo expiry' do
        AlaveteliPro::Embargo.expire_publishable
        expiry_events = info_request.
                          reload.
                            info_request_events.
                              where(:event_type => 'expire_embargo')
        expect(expiry_events.size).to eq 1
      end

    end

    context 'for an embargo whose publish_at date has passed' do
      let!(:embargo) do
        FactoryBot.create(:embargo, publish_at: Time.now - 2.days)
      end

      let!(:info_request) { embargo.info_request }

      it_behaves_like 'successful_expiry'

      context 'when the request is part of a batch' do
        let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

        before do
          info_request.info_request_batch = info_request_batch
          info_request_batch.sent_at = info_request.created_at
          info_request_batch.embargo_duration = '3_months'
          info_request_batch.save!
          info_request.save!
        end

        it_behaves_like 'successful_expiry'

        it 'deletes the embargo_duration from the batch' do
          AlaveteliPro::Embargo.expire_publishable
          expect(info_request_batch.reload.embargo_duration).to be_nil
        end
      end

      context 'when the request has use_notifications: true' do

        it 'notifies the user of the event' do
          info_request = FactoryBot.create(:use_notifications_request)
          embargo = FactoryBot.create(:expiring_embargo,
                                      info_request: info_request)
          embargo.update_attribute(:publish_at, Time.zone.today - 4.months)
          AlaveteliPro::Embargo.expire_publishable
          expect(Notification.count).to eq 1
        end

      end

      context 'when the request has use_notifications: false' do

        it 'does not notify the user of the event' do
          AlaveteliPro::Embargo.expire_publishable
          expect(Notification.count).to eq 0
        end

      end

    end

    context 'for an embargo whose publish_at date is today' do
      it 'does not expire the embargo' do
        embargo = FactoryBot.create(:embargo)
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
    let(:embargo) { FactoryBot.create(:embargo) }

    it "returns a date 1 week less than the publish_at" do
      expected = embargo.publish_at - 1.week
      expect(embargo.calculate_expiring_notification_at).to eq expected
    end
  end

  describe '.log_expiring_events' do
    let!(:expiring_soon_embargo) do
      FactoryBot.create(
        :expiring_embargo,
        info_request: FactoryBot.create(:use_notifications_request)
      )
    end
    let!(:expiring_soon_embargo_2) do
      FactoryBot.create(
        :expiring_embargo,
        info_request: FactoryBot.create(:use_notifications_request)
      )
    end
    let!(:expiring_later_embargo) do
      FactoryBot.create(
        :expiring_embargo,
        info_request: FactoryBot.create(:use_notifications_request),
        publish_at: Time.zone.now + 10.days
      )
    end
    let!(:non_notifications_embargo) { FactoryBot.create(:expiring_embargo) }

    def log_expiring_events
      AlaveteliPro::Embargo.log_expiring_events
    end

    def event_count
      InfoRequestEvent.where(event_type: 'embargo_expiring').count
    end

    it 'logs events for every embargo that is or was expiring soon' do
      expect { log_expiring_events }.to change { event_count }.by(3)
    end

    it 'sets the event created_at time to expiring_notification_at time' do
      log_expiring_events
      events = InfoRequestEvent.where(event_type: 'embargo_expiring')
      events.each do |e|
        embargo_expiring_at = e.info_request.embargo.expiring_notification_at
        expect(e.created_at).to eq embargo_expiring_at
      end
    end

    it "doesn't log events for the same expiry twice" do
      log_expiring_events
      expect { log_expiring_events }.not_to change { event_count }
    end

    it "doesn't log events for embargoes expiring further in the future" do
      log_expiring_events
      events = InfoRequestEvent.where(
        event_type: 'embargo_expiring',
        info_request_id: expiring_later_embargo.info_request_id)
      expect(events).to be_empty
    end

    context 'if embargoes have expired before events were logged' do
      let!(:expired_embargo) do
        FactoryBot.create(:embargo, publish_at: Time.zone.now - 1.day)
      end

      it 'still logs events for when they would have been expiring' do
        log_expiring_events
        events = InfoRequestEvent.where(
          event_type: 'embargo_expiring',
          info_request_id: expired_embargo.info_request_id)
        expect(events).to exist
        expect(events.count).to eq 1
        expected_created_at = expired_embargo.expiring_notification_at
        expect(events.first.created_at).to eq expected_created_at
      end
    end

    context 'when an embargo is extended' do
      let(:embargo_extension) do
        FactoryBot.create(:embargo_extension, embargo: expiring_soon_embargo)
      end
      let(:info_request_id) { expiring_soon_embargo.info_request_id }

      def event_count
        InfoRequestEvent.where(event_type: 'embargo_expiring',
                               info_request_id: info_request_id).count
      end

      context "if it's run before and after the extension" do
        it 'logs events for both expiries' do
          expect { log_expiring_events }.to change { event_count }.by(1)
          expiring_soon_embargo.extend(embargo_extension)
          time_travel_to(expiring_soon_embargo.publish_at - 6.days) do
            expect { log_expiring_events }.to change { event_count }.by(1)
          end
        end
      end

      context "if it's run just once after the extension" do
        it "only logs an event for the later expiry" do
          expiring_soon_embargo.extend(embargo_extension)
          time_travel_to(expiring_soon_embargo.publish_at - 6.days) do
            expect { log_expiring_events }.to change { event_count }.by(1)
          end
        end
      end
    end

    context "when the request has use_notifications: true" do
      it "notifies the user of the event" do
        expect { log_expiring_events }.
          to change { Notification.count }.by(2)
      end
    end

    context "when the request has use_notifications: false" do
      it "does not notify the user of the event" do
        log_expiring_events
        non_notifications_event = InfoRequestEvent.where(
          event_type: 'embargo_expiring',
          info_request_id: non_notifications_embargo.info_request_id
        )
        notifications = Notification.where(
          info_request_event_id: non_notifications_event
        )
        expect(notifications).not_to exist
      end
    end
  end

end

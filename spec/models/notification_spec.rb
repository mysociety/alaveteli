# == Schema Information
# Schema version: 20220210114052
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  info_request_event_id :integer          not null
#  user_id               :integer          not null
#  frequency             :integer          default("instantly"), not null
#  seen_at               :datetime
#  send_after            :datetime         not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  expired               :boolean          default(FALSE)
#

require "spec_helper"

RSpec.describe Notification do
  it "requires an info_request_event" do
    notification = FactoryBot.build(:notification,
                                    info_request_event: nil,
                                    user: FactoryBot.create(:user))
    expect(notification).not_to be_valid
  end

  it "requires a user" do
    notification = FactoryBot.build(:notification, user: nil)
    expect(notification).not_to be_valid
  end

  it "requires a frequency" do
    notification = FactoryBot.build(:notification, frequency: nil)
    expect(notification).not_to be_valid
  end

  describe "setting send_after" do
    context "when frequency is 'instantly'" do
      let(:notification) { FactoryBot.create(:instant_notification) }

      it "sets send_after to Time.zone.now" do
        expect(notification.send_after).to be_within(1.second).of(Time.zone.now)
      end
    end

    context "when the frequency is 'daily'" do
      let(:user) { FactoryBot.create(:user) }
      let(:notification) do
        FactoryBot.create(:daily_notification, user: user)
      end
      let(:user_time) { Time.zone.now + 3.hours }

      before do
        allow(user).to receive(:next_daily_summary_time).and_return(user_time)
      end

      it "sets send_after to the user's next daily summary time" do
        expect(notification.send_after).to be_within(1.second).of(user_time)
      end
    end

    context "when the notification has already been created" do
      let(:notification) { FactoryBot.create(:instant_notification) }
      let(:new_time) { expected_time = Time.zone.now + 3.hours }

      it "doesn't recalculate the send_after" do
        notification.send_after = new_time
        notification.save!
        expect(notification.send_after).to be_within(1.second).of(new_time)
      end
    end

    context "when the send_after time is set manually during creating" do
      let(:delayed_time) { expected_time = Time.zone.now + 3.hours }
      let(:notification) do
        FactoryBot.create(:instant_notification, send_after: delayed_time)
      end

      it "doesn't overwrite it" do
        expect(notification.send_after).to be_within(1.second).of(delayed_time)
      end
    end
  end

  describe ".unseen" do
    let!(:unseen_notification) do
      FactoryBot.create(:notification, seen_at: nil)
    end
    let!(:seen_notification) do
      FactoryBot.create(:notification, seen_at: Time.zone.now)
    end

    it "only returns unseen notifications" do
      expect(Notification.unseen).to match_array([unseen_notification])
    end
  end

  describe ".reject_and_mark_expired" do
    let(:notification) { FactoryBot.create(:notification) }
    let(:embargo_expiring_request) do
      FactoryBot.create(:embargo_expiring_request)
    end
    let(:embargo_expiring_event) do
      FactoryBot.create(:embargo_expiring_event,
                        info_request: embargo_expiring_request)
    end
    let(:expired_notification) do
      FactoryBot.create(:notification,
                        info_request_event: embargo_expiring_event)
    end
    let(:notifications) { [notification, expired_notification] }

    context "when no notifications are expired" do
      it "returns the original list" do
        expect(Notification.reject_and_mark_expired(notifications)).
          to match_array(notifications)
      end
    end

    context "when notifications are expired" do
      before do
        embargo_expiring_request.embargo.destroy!
        expired_notification.reload
      end

      it "returns a list of only valid notifications" do
        expect(Notification.reject_and_mark_expired(notifications)).
          to match_array([notification])
      end

      it "updates the expired notifications in the database" do
        expect(expired_notification.read_attribute(:expired)).to be false
        Notification.reject_and_mark_expired(notifications)
        expect(expired_notification.reload.read_attribute(:expired)).to be true
      end
    end
  end

  describe "#expired" do
    context "when the notification is for a new response" do
      let(:notification) { FactoryBot.create(:notification) }

      it "returns false" do
        expect(notification.expired).to be false
      end
    end

    context "when the notification is for an expiring embargo" do
      let(:embargo_expiring_request) do
        FactoryBot.create(:embargo_expiring_request)
      end
      let(:embargo_expiring_event) do
        FactoryBot.create(:embargo_expiring_event,
                          info_request: embargo_expiring_request)
      end
      let(:notification) do
        FactoryBot.create(:notification,
                          info_request_event: embargo_expiring_event)
      end

      context "and the embargo is still expiring" do
        it "returns false" do
          expect(notification.expired).to be false
        end
      end

      context 'and the expiry of the embargo is pending' do

        it 'returns false when the publication date has been reached' do
          travel_to(embargo_expiring_request.embargo.publish_at) do
            expect(notification.expired).to be false
          end
        end

        it 'returns false when the publication date has passed' do
          travel_to(embargo_expiring_request.embargo.publish_at + 1.day) do
            expect(notification.expired).to be false
          end
        end

      end

      context "and the embargo has been removed" do
        before do
          embargo_expiring_request.embargo.destroy!
          notification.reload
        end

        it "returns true" do
          expect(notification.expired).to be true
        end
      end
    end

    context 'when the notification is for an expired embargo' do
      let(:embargo_expired_request) do
        FactoryBot.create(:embargo_expired_request)
      end

      let(:embargo_expired_event) do
        FactoryBot.create(:expire_embargo_event,
                          info_request: embargo_expired_request)
      end

      let(:notification) do
        FactoryBot.create(:notification,
                          info_request_event: embargo_expired_event)
      end

      context 'and a new embargo has not been created' do

        it 'returns false' do
          expect(notification.expired).to be false
        end

      end

      context 'and a new embargo has been created' do

        before do
          FactoryBot.create(:embargo, info_request: embargo_expired_request)
          notification.reload
        end

        it 'returns true' do
          expect(notification.expired).to be true
        end

      end

    end

    context "when the notification is for an overdue request" do
      let(:info_request) { FactoryBot.create(:overdue_request) }
      let(:event) do
        FactoryBot.create(:overdue_event, info_request: info_request)
      end
      let(:notification) do
        FactoryBot.create(:notification, info_request_event: event)
      end

      context "and the request is still overdue" do
        context "and the user can make followups" do
          it "returns false" do
            expect(notification.expired).to be false
          end
        end

        context "and the user can't make followups" do
          before do
            info_request.user.update(ban_text: 'banned')
          end

          it "returns true" do
            expect(notification.expired).to be true
          end
        end
      end

      context "and the request is no longer overdue" do
        before do
          info_request.set_described_state('successful')
        end

        context "and the user can make followups" do
          it "returns true" do
            expect(notification.expired).to be true
          end
        end

        context "and the user can't make followups" do
          before do
            info_request.user.update(ban_text: 'banned')
          end

          it "returns true" do
            expect(notification.expired).to be true
          end
        end
      end
    end

    context "when the notification is for a very overdue request" do
      let(:info_request) { FactoryBot.create(:very_overdue_request) }
      let(:event) do
        FactoryBot.create(:very_overdue_event, info_request: info_request)
      end
      let(:notification) do
        FactoryBot.create(:notification, info_request_event: event)
      end

      context "and the request is still very_overdue" do
        context "and the user can make followups" do
          it "returns false" do
            expect(notification.expired).to be false
          end
        end

        context "and the user can't make followups" do
          before do
            info_request.user.update(ban_text: 'banned')
          end

          it "returns true" do
            expect(notification.expired).to be true
          end
        end
      end

      context "and the request is no longer very overdue" do
        before do
          info_request.set_described_state('successful')
        end

        context "and the user can make followups" do
          it "returns true" do
            expect(notification.expired).to be true
          end
        end

        context "and the user can't make followups" do
          before do
            info_request.user.update(ban_text: 'banned')
          end

          it "returns true" do
            expect(notification.expired).to be true
          end
        end
      end
    end
  end

  describe "#expired?" do
    let(:notification) { FactoryBot.create(:notification) }

    it "calls #expired" do
      expect(notification).to receive(:expired)
      notification.expired?
    end
  end
end

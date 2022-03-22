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

class Notification < ApplicationRecord
  belongs_to :info_request_event,
             :inverse_of => :notifications
  belongs_to :user,
             :inverse_of => :notifications

  INSTANTLY = :instantly
  DAILY = :daily
  enum frequency: [ INSTANTLY, DAILY ]

  validates_presence_of :info_request_event, :user, :frequency, :send_after

  before_validation :calculate_send_after

  scope :unseen, -> { where(seen_at: nil) }

  # Set the send_at timestamp based on the chosen frequency
  def calculate_send_after
    unless self.persisted? || self.send_after.present?
      if self.daily?
        self.send_after = self.user.next_daily_summary_time
      else
        self.send_after = Time.zone.now
      end
    end
  end

  # Return an Enumerable without expired notifications in it, saving the new
  # expired status at the same time
  def self.reject_and_mark_expired(notifications)
    expired_ids = notifications.select(&:expired).map(&:id)
    if expired_ids.empty?
      return notifications
    else
      Notification.where(id: expired_ids).update_all(expired: true)
      return notifications.reject { |n| expired_ids.include?(n.id) }
    end
  end

  # Overriden #expired? so that we can check against the actual current state
  # of our request (or whatever else might expire a notification)
  def expired
    send("#{info_request_event.event_type}_expired".to_sym)
  end

  def expired?
    expired
  end

  private

  def response_expired
    # New response notifications never expire
    false
  end

  def embargo_expiring_expired
    # If someone has changed the embargo date on the request, or published it,
    # they might not need this notification any more.
    if (info_request_event.info_request.embargo_expiring? ||
        info_request_event.info_request.embargo_pending_expiry?)
      false
    else
      true
    end
  end

  def expire_embargo_expired
    # If someone has added a new embargo, they might not need this notification
    # any more.
    !info_request_event.info_request.embargo_expired?
  end

  def overdue_expired
    info_request = self.info_request_event.info_request
    user = info_request.user
    status = info_request.calculate_status
    !(user.can_make_followup? && status == 'waiting_response_overdue')
  end

  def very_overdue_expired
    info_request = self.info_request_event.info_request
    user = info_request.user
    status = info_request.calculate_status
    !(user.can_make_followup? && status == 'waiting_response_very_overdue')
  end
end

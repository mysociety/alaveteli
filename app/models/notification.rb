# -*- encoding : utf-8 -*-
class Notification < ActiveRecord::Base
  belongs_to :info_request_event
  belongs_to :user

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
end

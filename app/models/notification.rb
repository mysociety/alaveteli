# -*- encoding : utf-8 -*-
class Notification < ActiveRecord::Base
  belongs_to :info_request_event
  belongs_to :user

  INSTANTLY = :instantly
  DAILY = :daily
  enum frequency: [ INSTANTLY, DAILY ]

  validates_presence_of :info_request_event, :user, :frequency, :send_after
end

# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20161128095350
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

class Embargo < ActiveRecord::Base
  belongs_to :info_request
  validates_presence_of :info_request
  validates_presence_of :publish_at
  validates_inclusion_of :embargo_duration,
                         in: lambda { |e| e.allowed_durations },
                         allow_nil: true
  after_initialize :set_publish_at_from_duration

  DURATIONS = {
    "3_months" => Proc.new { 3.months },
    "6_months" => Proc.new { 6.months },
    "12_months" => Proc.new { 12.months }
  }.freeze

  def allowed_durations
    DURATIONS.keys
  end

  def duration_as_duration
    DURATIONS[self.embargo_duration].call
  end

  def set_publish_at_from_duration
    unless self.publish_at.present? || self.embargo_duration.blank?
      self.publish_at = Time.zone.today + duration_as_duration
    end
  end

end

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
module AlaveteliPro
  class Embargo < ActiveRecord::Base
    belongs_to :info_request,
               :inverse_of => :embargo
    has_many :embargo_extensions,
             :inverse_of => :embargo
    has_one :user,
            :inverse_of => :embargoes,
            :through => :info_request

    validates_presence_of :info_request
    validates_presence_of :publish_at
    validates_inclusion_of :embargo_duration,
                           in: lambda { |e| e.allowed_durations },
                           allow_nil: true
    after_initialize :set_default_duration,
                     :set_publish_at_from_duration,
                     :set_expiring_notification_at
    around_save :add_set_embargo_event
    attr_accessor :extension

    # We're using some approximations here as months are not always the same length
    # and we want embargo arithmetic to be predictable
    THREE_MONTHS = 91.days
    SIX_MONTHS = 182.days
    TWELVE_MONTHS = 364.days

    DURATIONS = {
      "3_months" => Proc.new { THREE_MONTHS },
      "6_months" => Proc.new { SIX_MONTHS },
      "12_months" => Proc.new { TWELVE_MONTHS }
    }.freeze

    scope :expiring, -> { where("publish_at <= ?", expiring_soon_time) }

    def set_default_duration
      self.embargo_duration  ||= "3_months"
    end

    def allowed_durations
      DURATIONS.keys
    end

    def duration_as_duration(duration = nil)
      duration ||= self.embargo_duration
      DURATIONS[duration].call
    end

    def duration_label
      TranslatedConstants.duration_labels[self.embargo_duration]
    end

    def extend(extension)
      self.extension = extension
      self.publish_at += duration_as_duration(extension.extension_duration)
      self.expiring_notification_at = calculate_expiring_notification_at
      save
    end

    def calculate_expiring_notification_at
      self.publish_at - 1.week
    end

    def self.expiring_soon_time
      Time.zone.now + 1.week
    end

    def self.expire_publishable
      beginning_of_day = Time.zone.now.beginning_of_day
      where(['publish_at < ?', beginning_of_day]).find_each do |embargo|
        embargo.info_request.log_event('expire_embargo', {})
        embargo.destroy
      end
    end

    def self.three_months_from_now
      Time.zone.now.beginning_of_day + THREE_MONTHS
    end

    def self.six_months_from_now
      Time.zone.now.beginning_of_day + SIX_MONTHS
    end

    def self.twelve_months_from_now
      Time.zone.now.beginning_of_day + TWELVE_MONTHS
    end

    def self.log_expiring_events
      query = "LEFT JOIN info_request_events ire
                   ON ire.info_request_id = embargoes.info_request_id
                   AND ire.created_at = embargoes.expiring_notification_at
                   AND ire.event_type = 'embargo_expiring'"
      embargoes = expiring.joins(query).where("ire.info_request_id IS NULL")
      embargoes.find_each do |embargo|
        info_request = embargo.info_request
        event = info_request.log_event(
          'embargo_expiring',
          { :event_created_at => Time.zone.now },
          { :created_at => embargo.expiring_notification_at })
        info_request.user.notify(event)
      end
    end

    private

    def add_set_embargo_event
      publish_at_changed = self.publish_at_changed?
      yield
      if publish_at_changed
        params = { :embargo_id => self.id }
        if extension
          params[:embargo_extension_id] = extension.id
        end
        info_request.log_event('set_embargo', params)
      end
    end

    def set_publish_at_from_duration
      unless self.publish_at.present? || self.embargo_duration.blank?
        self.publish_at = Time.zone.now.beginning_of_day + duration_as_duration
      end
    end

    def set_expiring_notification_at
      unless self.expiring_notification_at.present?
        self.expiring_notification_at = calculate_expiring_notification_at
      end
    end
  end
end

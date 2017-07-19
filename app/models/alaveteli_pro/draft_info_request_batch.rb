# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20170323165519
#
# Table name: draft_info_request_batches
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  body             :text
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string(255)
#

class AlaveteliPro::DraftInfoRequestBatch < ActiveRecord::Base
  include AlaveteliPro::RequestSummaries

  belongs_to :user
  has_and_belongs_to_many :public_bodies, -> {
    I18n.with_locale(I18n.locale) do
      includes(:translations).
        reorder('public_body_translations.name asc')
    end
  }

  validates_presence_of :user

  after_initialize :set_default_body

  def set_default_body
    if body.blank?
      template = OutgoingMessage::Template::BatchRequest.new
      template_options = {}
      template_options[:info_request_title] = title if title
      self.body = template.body(template_options)
      if self.user
        self.body += self.user.name
      end
    end
  end

  # @see RequestSummaries#request_summary_body
  def request_summary_body
    self.body
  end

  # @see RequestSummaries#request_summary_public_body_names
  def request_summary_public_body_names
    self.public_bodies.pluck(:name).join(" ")
  end

  # @see RequestSummaries#request_summary_categories
  def request_summary_categories
    [AlaveteliPro::RequestSummaryCategory.draft]
  end
end

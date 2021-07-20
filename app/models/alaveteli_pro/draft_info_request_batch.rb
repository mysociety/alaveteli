# == Schema Information
# Schema version: 20210114161442
#
# Table name: draft_info_request_batches
#
#  id               :integer          not null, primary key
#  title            :string
#  body             :text
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string
#

class AlaveteliPro::DraftInfoRequestBatch < ApplicationRecord
  include AlaveteliPro::RequestSummaries
  include InfoRequest::DraftTitleValidation

  belongs_to :user,
             :inverse_of => :draft_info_request_batches
  has_and_belongs_to_many :public_bodies, -> {
    AlaveteliLocalization.with_locale(AlaveteliLocalization.locale) do
      includes(:translations).
        reorder('public_body_translations.name asc')
    end
  }, :inverse_of => :draft_info_request_batches

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

# == Schema Information
# Schema version: 20220322100510
#
# Table name: draft_info_requests
#
#  id               :bigint           not null, primary key
#  title            :string
#  user_id          :bigint
#  public_body_id   :bigint
#  body             :text
#  embargo_duration :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class DraftInfoRequest < ApplicationRecord
  include AlaveteliPro::RequestSummaries
  include InfoRequest::DraftTitleValidation

  validates_presence_of :user

  belongs_to :user,
             :inverse_of => :draft_info_requests
  belongs_to :public_body, :inverse_of => :draft_info_requests

  strip_attributes

  # @see RequestSummaries#request_summary_body
  def request_summary_body
    self.body
  end

  # @see RequestSummaries#request_summary_public_body_names
  def request_summary_public_body_names
    self.public_body.name unless self.public_body.blank?
  end

  # @see RequestSummaries#request_summary_categories
  def request_summary_categories
    [AlaveteliPro::RequestSummaryCategory.draft]
  end
end

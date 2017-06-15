# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20161128095350
#
# Table name: draft_info_requests
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  user_id          :integer
#  public_body_id   :integer
#  body             :text
#  embargo_duration :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class DraftInfoRequest < ActiveRecord::Base
  include AlaveteliPro::RequestSummaries

  validates_presence_of :user

  belongs_to :user
  belongs_to :public_body

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

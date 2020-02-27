# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: request_summary_categories
#
#  id         :integer          not null, primary key
#  slug       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AlaveteliPro::RequestSummaryCategory < ApplicationRecord
  has_and_belongs_to_many :request_summaries,
                          class_name: "AlaveteliPro::RequestSummary",
                          inverse_of: :request_summary_categories

  def self.draft
    find_by(slug: "draft")
  end

  def self.complete
    find_by(slug: 'complete')
  end

  def self.clarification_needed
    find_by(slug: 'clarification_needed')
  end

  def self.awaiting_response
    find_by(slug: 'awaiting_response')
  end

  def self.response_received
    find_by(slug: 'response_received')
  end

  def self.overdue
    find_by(slug: 'overdue')
  end

  def self.very_overdue
    find_by(slug: 'very_overdue')
  end

  def self.other
    find_by(slug: 'other')
  end

  def self.embargo_expiring
    find_by(slug: 'embargo_expiring')
  end
end

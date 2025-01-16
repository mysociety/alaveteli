# == Schema Information
# Schema version: 20241007090524
#
# Table name: citations
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  citable_type :string
#  citable_id   :integer
#  source_url   :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  title        :string
#  description  :text
#

##
# A Citation of an InfoRequest or InfoRequestBatch
#
class Citation < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LinkToHelper

  self.inheritance_column = nil

  belongs_to :user, inverse_of: :citations
  belongs_to :citable, polymorphic: true

  belongs_to :info_request, via: :citable, optional: true
  belongs_to :info_request_batch, via: :citable, optional: true

  validates :citable_type, inclusion: { in: %w(InfoRequest InfoRequestBatch) }
  validates :source_url, length: { maximum: 255,
                                   message: _('Source URL is too long') },
                         format: { with: /\Ahttps?:\/\/.*\z/,
                                   message: _('Please enter a Source URL') }
  validates :type, inclusion: { in: %w(journalism research campaigning other),
                                message: _('Please select a type') }

  scope :newest, ->(limit = 1) do
    order(created_at: :desc).limit(limit)
  end

  scope :not_embargoed, -> do
    left_joins(info_request: :embargo, info_request_batch: []).
      where(citable_type: 'InfoRequest').
      merge(InfoRequest.not_embargoed).
      or(
        where(citable_type: 'InfoRequestBatch').
        merge(InfoRequestBatch.not_embargoed)
      )
  end

  scope :for_request, ->(info_request) do
    where(citable: info_request).
      or(where(citable: info_request.info_request_batch))
  end

  scope :for_batch, ->(info_request_batch) do
    where(citable: info_request_batch).
      or(where(citable: info_request_batch.info_requests))
  end

  def self.search(query)
    where(<<~SQL, query: query)
      lower(citations.source_url) LIKE lower('%'||:query||'%')
    SQL
  end

  def applies_to_batch_request?
    citable.is_a?(InfoRequestBatch)
  end

  def as_json(_options)
    citable_path = case citable
                   when InfoRequest
                     request_path(citable)
                   when InfoRequestBatch
                     info_request_batch_path(citable)
                   end

    attributes.
      except('user_id', 'citable_id', 'citable_type').
      merge(citable_path: citable_path)
  end
end

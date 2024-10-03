# == Schema Information
# Schema version: 20210114161442
#
# Table name: citations
#
#  id           :bigint           not null, primary key
#  user_id      :bigint
#  citable_type :string
#  citable_id   :bigint
#  source_url   :string
#  type         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

##
# A Citation of an InfoRequest or InfoRequestBatch
#
class Citation < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :user, inverse_of: :citations
  belongs_to :citable, polymorphic: true

  belongs_to :info_request, via: :citable
  belongs_to :info_request_batch, via: :citable

  validates :user, :citable, presence: true
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

  def applies_to_batch_request?
    citable.is_a?(InfoRequestBatch)
  end
end

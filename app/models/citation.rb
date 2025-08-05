# == Schema Information
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
#

##
# A Citation of an InfoRequest or InfoRequestBatch in news stories or an
# academic paper
#
class Citation < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :user, inverse_of: :citations
  belongs_to :citable, polymorphic: true

  validates :user, :citable, presence: true
  validates :citable_type, inclusion: { in: %w(InfoRequest InfoRequestBatch) }
  validates :source_url, length: { maximum: 255,
                                   message: _('Source URL is too long') },
                         format: { with: /\Ahttps?:\/\/.*\z/,
                                   message: _('Please enter a Source URL') }
  validates :type, inclusion: { in: %w(news_story academic_paper other),
                                message: _('Please select a type') }

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

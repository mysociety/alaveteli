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

  scope :for_request, ->(info_request) do
    where(citable: info_request).
      or(where(citable: info_request.info_request_batch))
  end

  scope :for_batch, ->(info_request_batch) do
    where(citable: info_request_batch).
      or(where(citable: info_request_batch.info_requests))
  end
end

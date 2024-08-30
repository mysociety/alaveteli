# == Schema Information
# Schema version: 20240905062817
#
# Table name: chunks
#
#  id                  :bigint           not null, primary key
#  info_request_id     :bigint
#  incoming_message_id :bigint
#  foi_attachment_id   :bigint
#  text                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  embedding           :vector(4096)
#

##
# This class represents a chunk of text for which embedding vectors are
# generated.
#
class Chunk < SecondaryRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :info_request
  belongs_to :incoming_message
  belongs_to :foi_attachment

  def as_vector
    text
  end
end

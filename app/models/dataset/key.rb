# == Schema Information
# Schema version: 20200501183111
#
# Table name: dataset_keys
#
#  id                 :integer          not null, primary key
#  dataset_key_set_id :integer
#  title              :string
#  format             :string
#  order              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

##
# A dataset key representing an value which should be extractable from a
# resource
#
class Dataset::Key < ApplicationRecord
  belongs_to :key_set, foreign_key: 'dataset_key_set_id'

  default_scope -> { order(:order) }

  FORMATS = %w[
    text
    numeric
    boolean
  ].freeze

  validates :title, :format, :order, presence: true
  validates :format, inclusion: { in: FORMATS }
  validates :order, uniqueness: { scope: :dataset_key_set_id }
end

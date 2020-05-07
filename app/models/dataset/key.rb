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
  has_many :values, foreign_key: 'dataset_key_id', inverse_of: :key

  default_scope -> { order(:order) }

  FORMATS = {
    text: /\A.*\z/,
    numeric: /\A[0-9,%\+\-\s]*\z/,
    boolean: /\A(0|1)\z/
  }.freeze

  validates :title, :format, :order, presence: true
  validates :format, inclusion: { in: FORMATS.keys.map(&:to_s) }
  validates :order, uniqueness: { scope: :dataset_key_set_id }

  def format_regexp
    FORMATS[format.to_sym]
  end
end

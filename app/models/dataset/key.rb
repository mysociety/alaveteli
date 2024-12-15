# == Schema Information
# Schema version: 20240926164308
#
# Table name: dataset_keys
#
#  id                 :bigint           not null, primary key
#  dataset_key_set_id :bigint
#  title              :string
#  format             :string
#  order              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  options            :jsonb
#

##
# A dataset key representing an value which should be extractable from a
# resource
#
class Dataset::Key < ApplicationRecord
  belongs_to :key_set, foreign_key: 'dataset_key_set_id', optional: true
  has_many :values, foreign_key: 'dataset_key_id', inverse_of: :key

  default_scope -> { order(:order) }

  FORMATS = {
    text: { title: _('Text'), regexp: /\A.*\z/m },
    select: { title: _('Select'), regexp: /\A.*\z/m },
    numeric: { title: _('Numeric'), regexp: /\A[0-9,%\+\-\s]*\z/ },
    boolean: { title: _('Yes/No'), regexp: /\A(0|1)\z/ }
  }.freeze

  validates :title, :format, :order, presence: true
  validates :format, inclusion: { in: FORMATS.keys.map(&:to_s) }

  def self.format_options
    FORMATS.each_with_object({}) do |(key, detail), acc|
      acc[detail[:title]] = key
    end
  end

  def format_regexp
    FORMATS[format.to_sym][:regexp]
  end

  def select_options
    options.fetch('select_options', [])
  end

  def select_allow_blank?
    options.fetch('select_allow_blank', '0').to_i == 1
  end

  def select_allow_muliple?
    options.fetch('select_allow_muliple', '0').to_i == 1
  end
end

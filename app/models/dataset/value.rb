# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_values
#
#  id                   :integer          not null, primary key
#  dataset_value_set_id :integer
#  dataset_key_id       :integer
#  value                :string
#  notes                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

##
# A dataset value representing an extracted value for a given key
#
class Dataset::Value < ApplicationRecord
  belongs_to :value_set, foreign_key: 'dataset_value_set_id'
  belongs_to :key, foreign_key: 'dataset_key_id'

  validates :value_set, :key, presence: true
  validates :value,
            format: { with: -> (value) { value.key.format_regexp } },
            allow_blank: true,
            if: -> (value) { value.key }

  def title
    key.title
  end

  def value=(new_value)
    case key.format
    when 'select'
      super(Array(new_value).reject(&:blank?).join(', '))
    else
      super
    end
  end

  def mapped_value
    case key.format
    when 'boolean'
      value.to_i > 0 ? _('Yes') : _('No')
    else
      value
    end
  end
end

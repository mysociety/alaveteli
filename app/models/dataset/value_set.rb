# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_value_sets
#
#  id                 :integer          not null, primary key
#  resource_type      :string
#  resource_id        :integer
#  dataset_key_set_id :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

##
# A dataset collection of values
#
class Dataset::ValueSet < ApplicationRecord
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :key_set, foreign_key: 'dataset_key_set_id'
  has_many :values, foreign_key: 'dataset_value_set_id', inverse_of: :value_set

  accepts_nested_attributes_for :values

  RESOURCE_TYPES = %w[
    InfoRequest
    IncomingMessage
    FoiAttachment
  ].freeze

  validates :resource_type, inclusion: { in: RESOURCE_TYPES }, if: :resource
  validates_associated :values
  validate :check_at_least_one_value_is_present

  private

  def check_at_least_one_value_is_present
    return unless values.map(&:value).all?(&:blank?)

    errors.add :values, :empty
  end
end

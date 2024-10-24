# == Schema Information
# Schema version: 20241024140606
#
# Table name: insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  model           :string
#  temperature     :decimal(8, 2)
#  template        :text
#  output          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Insight < ApplicationRecord
  belongs_to :info_request, optional: false
  has_many :outgoing_messages, through: :info_request

  serialize :output, type: Hash, coder: JSON, default: {}

  validates :model, presence: true
  validates :temperature, presence: true
  validates :template, presence: true
end

# == Schema Information
# Schema version: 20241024140606
#
# Table name: insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  model           :string
#  temperature     :decimal(8, 2)
#  prompt_template :text
#  output          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Insight < ApplicationRecord
  admin_columns exclude: [:prompt_template, :output],
                include: [:duration, :prompt, :response]

  after_commit :queue, on: :create

  belongs_to :info_request, optional: false
  has_many :outgoing_messages, through: :info_request

  validates :model, presence: true
  validates :temperature, presence: true
  validates :prompt_template, presence: true

  def duration
    return unless output && output['total_duration']

    seconds = output['total_duration'].to_f / 1_000_000_000
    ActiveSupport::Duration.build(seconds.to_i).inspect
  end

  def prompt
    prompt_template.gsub('[initial_request]') do
      strip_tags(outgoing_messages.first.body)[0...500]
    end
  end

  def response
    output && output['response']
  end

  private

  def strip_tags(content)
    content.gsub(/<\|start_(.*?)\|>(.*?)<\|end_\1\|>/m, '').
            gsub(/<\|.*?\|>/, '')
  end

  def queue
    InsightJob.perform_later(insight: self)
  end
end

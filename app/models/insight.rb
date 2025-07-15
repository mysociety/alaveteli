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

  attr_reader :template

  belongs_to :info_request, optional: false
  has_many :outgoing_messages, through: :info_request

  validates :model, presence: true
  validates :temperature, presence: true
  validates :prompt_template, presence: true

  class << self
    def templates
      @templates ||= {}
    end

    def register_template(name, title:, attributes:)
      templates[name.to_sym] = {
        title: title,
        attributes: attributes
      }
    end
  end

  register_template :keywords,
    title: 'Extract 10 keywords',
    attributes: {
      model: 'Toast:latest', temperature: 0.3, prompt_template: <<~TXT
        <|start_header_id|>system<|end_header_id|>
        You are a helpful AI assistant that extracts the 10 most relevant keywords from text.
        Focus on:
        - Core subject matter and themes
        - Important factual details
        - Contextually relevant terms
        - Consistent formatting
        Return exactly 10 keywords that best represent the input text's subject matter, one per line. Return only the keywords. Do not include any other explanatory text.
        <|eot_id|>

        <|start_header_id|>user<|end_header_id|>
        Extract 10 relevant keywords from this text:
        [initial_request]
        <|eot_id|>

        <|start_header_id|>assistant<|end_header_id|>
      TXT
    }

  def template=(key)
    @template = key
    assign_attributes(self.class.templates[key.to_sym][:attributes])
  end

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

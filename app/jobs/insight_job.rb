##
# InsightJob is responsible for generating InfoRequest insights using an AI
# model run via Ollama.
#
class InsightJob < ApplicationJob
  queue_as :insights

  delegate :model, :temperature, :prompt, to: :@insight

  def perform(insight:)
    @insight = insight

    insight.update(output: results.first)
  end

  private

  def results
    client.generate(
      { model: model, prompt: prompt, temperature: temperature, stream: false }
    )
  end

  def client
    Ollama.new(
      credentials: { address: ENV['OLLAMA_URL'] },
      options: { server_sent_events: true }
    )
  end
end

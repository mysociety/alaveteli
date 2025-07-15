require 'spec_helper'

RSpec.describe InsightJob, type: :job do
  let(:insight) do
    FactoryBot.build('insight', model: 'gpt-3.5-turbo', temperature: 0.7)
  end

  let(:client) { instance_double('Ollama::Controllers::Client') }

  let(:job) { InsightJob.new }

  before do
    allow(job).to receive(:client).and_return(client)
    allow(insight).to receive(:prompt).and_return('Test prompt')
    allow(insight).to receive(:update)
  end

  describe '#perform' do
    it 'updates the insight with the generated output' do
      expect(client).to receive(:generate).with(
        hash_including(
          model: 'gpt-3.5-turbo',
          temperature: 0.7,
          prompt: 'Test prompt',
          stream: false
        )
      ).and_return(['Generated output'])

      expect(insight).to receive(:update).with(output: 'Generated output')

      job.perform(insight: insight)
    end
  end
end

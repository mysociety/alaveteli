require 'spec_helper'

RSpec.describe BotTrafficMetrics do
  before do
    described_class::EVENTS.each do |event|
      Rails.cache.delete(described_class.cache_key(event))
    end
  end

  it 'increments known event counters' do
    described_class.increment(:cache_hits)

    expect(described_class.snapshot[:cache_hits]).to eq(1)
  end

  it 'ignores unknown event counters' do
    described_class.increment(:unknown_event)

    expect(described_class.snapshot.values).to all(eq(0))
  end

  it 'returns zero counters when snapshot collection fails' do
    allow(Rails.cache).to receive(:read).and_raise(StandardError, 'cache down')
    allow(Rails.logger).to receive(:error)

    expect(described_class.snapshot.values).to all(eq(0))
    expect(Rails.logger).to have_received(:error).
      with(/Bot traffic metric snapshot failed:/)
  end
end

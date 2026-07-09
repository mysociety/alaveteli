require 'spec_helper'

RSpec.describe BulkExportStreamer do
  let!(:old_request) do
    FactoryBot.create(
      :info_request,
      title: 'Older request',
      created_at: 3.days.ago,
      updated_at: 3.days.ago
    )
  end
  let!(:new_request) do
    FactoryBot.create(
      :info_request,
      title: 'Newer request',
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )
  end

  it 'streams selected rows in deterministic id order' do
    rows = described_class.new(batch_size: 1).each.to_a

    expect(rows.map { |row| row[:id] }).to eq([old_request.id, new_request.id])
    expect(rows.first).to include(
      title: old_request.title,
      public_body_name: old_request.public_body.name,
      public_body_url_name: old_request.public_body.url_name
    )
  end

  it 'enforces the limit without reading past the requested row count' do
    rows = described_class.new(limit: 1, batch_size: 1).each.to_a

    expect(rows.size).to eq(1)
    expect(rows.first[:id]).to eq(old_request.id)
  end

  it 'filters rows by updated timestamp' do
    rows = described_class.new(since: 2.days.ago, batch_size: 1).each.to_a

    expect(rows.map { |row| row[:id] }).to eq([new_request.id])
  end

  it 'preserves base calculated status for ordinary requests' do
    row = described_class.new(limit: 1).each.first

    expect(row[:status]).to eq(old_request.calculate_status)
  end

  it 'falls back to ActiveRecord status calculation for custom states' do
    allow(InfoRequest).to receive(:custom_states_loaded?).and_return(true)

    row = described_class.new(limit: 1).each.first

    expect(row[:status]).to eq(old_request.calculate_status)
  end
end

require 'spec_helper'
require 'csv'

# Not a real test - a throwaway diagnostic that builds one record per
# redactable attribute, seeds a CensorRule matching "bananas", reads the
# attribute back, and appends the result as a column in a CSV file so the
# same attribute's output can be diffed across branches.
#
# Usage:
#   BRANCH_LABEL=develop bundle exec rspec spec/redactable_snapshot_spec.rb
#   BRANCH_LABEL=redactable bundle exec rspec spec/redactable_snapshot_spec.rb
#
# Then compare tmp/redactable_snapshot.csv's "develop" and "redactable"
# columns. This file is untracked by design - copy it out before switching
# branches if the target branch doesn't have it (e.g. develop).
RSpec.describe 'Redactable snapshot' do
  CSV_PATH = Rails.root.join('tmp', 'redactable_snapshot.csv')

  # attribute => raw value to store, containing "bananas" for the censor
  # rule to match
  ATTRS = {
    'IncomingMessage' => {
      from: nil, # no underlying accessor exists to seed; captured for completeness
      from_name: 'Some bananas name',
      from_email: 'bananas@example.com',
      from_email_domain: 'bananas.example.com',
      subject: 'Some bananas subject'
    },
    'OutgoingMessage' => {
      from: nil, # always derived from info_request, not stored on the record
      from_name: 'Some bananas sender',
      body: 'Some bananas body'
    },
    'FoiAttachment' => {
      filename: 'bananas-report.txt',
      body: 'Report about bananas pricing'
    }
  }.freeze

  it 'snapshots redactable attribute output' do
    label = ENV['BRANCH_LABEL']

    if label.blank?
      raise 'Set BRANCH_LABEL=<column name>, e.g. ' \
            'BRANCH_LABEL=develop bundle exec rspec spec/redactable_snapshot_spec.rb'
    end

    rows = build_rows

    write_csv(label, rows)

    puts "Wrote #{rows.size} rows to #{CSV_PATH} under column #{label.inspect}"
  end

  def build_rows
    info_request = FactoryBot.create(:info_request)
    CensorRule.create!(
      censorable: info_request,
      text: 'bananas',
      replacement: '[REDACTED]',
      last_edit_editor: 'redactable_snapshot_spec',
      last_edit_comment: 'Seeded by spec/redactable_snapshot_spec.rb'
    )

    incoming_message = build_incoming_message(info_request)
    outgoing_message = build_outgoing_message(info_request)
    foi_attachment = build_foi_attachment(incoming_message)

    records = {
      'IncomingMessage' => incoming_message,
      'OutgoingMessage' => outgoing_message,
      'FoiAttachment' => foi_attachment
    }

    rows = []
    ATTRS.each do |model_name, attrs|
      record = records.fetch(model_name)
      attrs.each do |attr, input|
        rows << {
          model: model_name,
          attribute: attr.to_s,
          input: input.inspect,
          output: read_attribute_safely(record, attr)
        }
      end
    end
    rows
  end

  def read_attribute_safely(record, attr)
    record.public_send(attr).inspect
  rescue StandardError => e
    "ERROR: #{e.class}: #{e.message}"
  end

  def build_incoming_message(info_request)
    incoming_message = FactoryBot.create(:incoming_message, info_request: info_request)
    incoming_message.update_columns(
      from_name: 'Some bananas name',
      from_email: 'bananas@example.com',
      from_email_domain: 'bananas.example.com',
      subject: 'Some bananas subject',
      last_parsed: Time.zone.now
    )
    IncomingMessage.find(incoming_message.id)
  end

  def build_outgoing_message(info_request)
    outgoing_message = FactoryBot.build(:initial_request, info_request: info_request)
    outgoing_message.assign_attributes(
      from_name: 'Some bananas sender',
      body: 'Some bananas body'
    )
    outgoing_message.save!(validate: false)
    OutgoingMessage.find(outgoing_message.id)
  end

  # The attachment's content must actually be present in the incoming
  # message's raw email, or reading #body triggers FoiAttachment::MaskJob's
  # "attachment missing" fallback, which re-parses the raw email looking for
  # a hexdigest match that will never be found - and burns a lot of CPU/
  # memory doing it. So we overwrite the factory's default attachment, then
  # rebuild the raw email to match it.
  #
  # We also need a *fresh* instance to read #body from: FoiAttachment#body=
  # (called both by us here, and by the masking pipeline) caches its
  # argument in @cached_body, and the reader returns that in preference to
  # ever running the masking pipeline - so the same in-memory object would
  # just hand back the unmasked text we seeded it with.
  def build_foi_attachment(incoming_message)
    attachment = incoming_message.foi_attachments.first
    attachment.update_columns(masked_at: nil)
    attachment.filename = 'bananas-report.txt'
    attachment.body = 'Report about bananas pricing'
    attachment.save!

    mail = build_incoming_message_mail(incoming_message)
    incoming_message.raw_email.data = mail
    incoming_message.raw_email.save!

    FoiAttachment.find(attachment.id)
  end

  def write_csv(label, rows)
    existing = read_existing_csv

    rows.each do |row|
      key = [row[:model], row[:attribute]]
      existing[key] ||= { model: row[:model], attribute: row[:attribute] }
      existing[key][:input] = row[:input]
      existing[key][label] = row[:output]
    end

    labels = existing.values.flat_map(&:keys).
      reject { |k| %i[model attribute input].include?(k) }.uniq
    headers = [:model, :attribute, :input] + labels

    CSV.open(CSV_PATH, 'w') do |csv|
      csv << headers
      existing.each_value { |row| csv << headers.map { |h| row[h] } }
    end
  end

  def read_existing_csv
    return {} unless File.exist?(CSV_PATH)

    rows = {}
    CSV.foreach(CSV_PATH, headers: true) do |row|
      hash = row.to_h
      key = [hash['model'], hash['attribute']]
      entry = { model: hash['model'], attribute: hash['attribute'], input: hash['input'] }
      hash.each { |k, v| entry[k] = v unless %w[model attribute input].include?(k) }
      rows[key] = entry
    end
    rows
  end
end

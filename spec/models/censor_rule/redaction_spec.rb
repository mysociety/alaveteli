# == Schema Information
#
# Table name: censor_rule_redactions
#
#  id                 :bigint           not null, primary key
#  censor_rule_id     :bigint           not null
#  redactable_type    :string           not null
#  redactable_id      :bigint           not null
#  redacted_attribute :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'spec_helper'

RSpec.describe CensorRule::Redaction do
  describe '.for_request' do
    subject { described_class.for_request(info_request) }

    let(:info_request) { FactoryBot.create(:info_request) }
    let(:other_request) { FactoryBot.create(:info_request) }
    let(:rule) { FactoryBot.create(:global_censor_rule) }

    def create_redaction(redactable)
      CensorRule::Redaction.create!(censor_rule: rule, redactable: redactable,
                                    redacted_attribute: 'body')
    end

    it 'includes redactions for outgoing messages on the request' do
      om = info_request.outgoing_messages.first
      redaction = create_redaction(om)
      is_expected.to include(redaction)
    end

    it 'excludes redactions for outgoing messages on other requests' do
      om = other_request.outgoing_messages.first
      redaction = create_redaction(om)
      is_expected.not_to include(redaction)
    end

    it 'includes redactions for incoming messages on the request' do
      im = FactoryBot.create(:incoming_message, info_request: info_request)
      redaction = create_redaction(im)
      is_expected.to include(redaction)
    end

    it 'excludes redactions for incoming messages on other requests' do
      im = FactoryBot.create(:incoming_message, info_request: other_request)
      redaction = create_redaction(im)
      is_expected.not_to include(redaction)
    end

    it 'includes redactions for attachments on the request' do
      im = FactoryBot.create(:incoming_message, info_request: info_request)
      attachment = FactoryBot.create(:foi_attachment, incoming_message: im)
      redaction = create_redaction(attachment)
      is_expected.to include(redaction)
    end

    it 'excludes redactions for attachments on other requests' do
      im = FactoryBot.create(:incoming_message, info_request: other_request)
      attachment = FactoryBot.create(:foi_attachment, incoming_message: im)
      redaction = create_redaction(attachment)
      is_expected.not_to include(redaction)
    end

    it 'includes redactions for the info request itself' do
      redaction = create_redaction(info_request)
      is_expected.to include(redaction)
    end

    it 'excludes redactions for other info requests' do
      redaction = create_redaction(other_request)
      is_expected.not_to include(redaction)
    end
  end
end

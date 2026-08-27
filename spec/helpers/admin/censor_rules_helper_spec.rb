require 'spec_helper'

RSpec.describe Admin::CensorRulesHelper do
  include AdminHelper # Dependencies for `both_links`
  include Admin::CensorRulesHelper

  describe '#censor_rule_applies_to' do
    subject { censor_rule_applies_to(censor_rule) }

    context 'with an info_request censor rule' do
      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with an public_body censor rule' do
      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with a user censor rule' do
      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }
      it { is_expected.to eq(both_links(censor_rule.censorable)) }
    end

    context 'with a global censor rule' do
      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }
      it { is_expected.to eq('<strong>everything</strong>') }
    end
  end

  describe '#censor_rule_redaction_counts' do
    subject { censor_rule_redaction_counts(censor_rules, info_request) }

    let(:info_request) { FactoryBot.create(:info_request_with_incoming) }
    let(:incoming_message) { info_request.incoming_messages.first }
    let(:outgoing_message) { info_request.outgoing_messages.first }
    let(:censor_rules) { [rule, other_rule] }
    let(:rule) { FactoryBot.create(:global_censor_rule) }
    let(:other_rule) { FactoryBot.create(:global_censor_rule) }

    def record_redaction(censor_rule, redactable, attribute = :body)
      censor_rule.redactions.create!(
        redactable: redactable, redacted_attribute: attribute
      )
    end

    context 'when no redactions have been recorded' do
      it { is_expected.to eq({}) }
    end

    context 'when there is no request' do
      let(:info_request) { nil }
      it { is_expected.to eq({}) }
    end

    it 'counts redactions against the request' do
      record_redaction(rule, info_request, :title)
      is_expected.to eq(rule.id => 1)
    end

    it 'counts redactions against outgoing messages' do
      record_redaction(rule, outgoing_message)
      is_expected.to eq(rule.id => 1)
    end

    it 'counts redactions against incoming messages' do
      record_redaction(rule, incoming_message)
      is_expected.to eq(rule.id => 1)
    end

    it 'counts redactions against attachments' do
      record_redaction(rule, incoming_message.foi_attachments.first)
      is_expected.to eq(rule.id => 1)
    end

    it 'counts each rule separately' do
      record_redaction(rule, incoming_message)
      record_redaction(rule, outgoing_message)
      record_redaction(other_rule, outgoing_message)

      is_expected.to eq(rule.id => 2, other_rule.id => 1)
    end

    it 'excludes rules which are not given' do
      excluded = FactoryBot.create(:global_censor_rule)
      record_redaction(excluded, incoming_message)

      is_expected.to eq({})
    end

    it 'excludes redactions belonging to another request' do
      other_request = FactoryBot.create(:info_request_with_incoming)
      record_redaction(rule, other_request.incoming_messages.first)

      is_expected.to eq({})
    end
  end
end

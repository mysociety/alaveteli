require 'spec_helper'

RSpec.describe CensorRule::Permanence, feature: :redaction_tracking do
  let(:incoming_message) do
    FactoryBot.create(:incoming_message, :with_text_attachment)
  end

  let(:info_request) { incoming_message.info_request }
  let(:attachment) { incoming_message.foi_attachments.last }

  let(:rule) do
    FactoryBot.create(:censor_rule, censorable: info_request,
                                    text: 'isthe', replacement: '[x]')
  end

  before do
    rule
    attachment.reload.mask
  end

  describe '#redacted_incoming_messages' do
    it 'includes messages with redacted attachments' do
      expect(rule.redacted_incoming_messages).to include(incoming_message)
    end
  end

  describe '#make_permanent' do
    before { rule.make_permanent(editor: 'admin') }

    it 'locks the attachments' do
      expect(attachment.reload).to be_locked
    end

    it 'erases the raw email' do
      expect(incoming_message.raw_email.reload).to be_erased
    end

    it 'keeps the redactions once the rule is erased' do
      rule.erase(editor: 'admin')
      expect(attachment.reload.body).to eq('here[x]text')
    end
  end

  describe 'outgoing messages' do
    let(:outgoing_message) { info_request.outgoing_messages.first }

    let(:rule) do
      FactoryBot.create(:censor_rule, censorable: info_request,
                                      text: 'information', replacement: '[x]')
    end

    before do
      outgoing_message.body
      rule.make_permanent(editor: 'admin')
      rule.erase(editor: 'admin')
    end

    it 'keeps the redactions once the rule is erased' do
      expect(outgoing_message.reload.body).not_to include('information')
    end

    it 'stores the redacted body' do
      expect(outgoing_message.reload.body).to include('[x]')
    end
  end
end

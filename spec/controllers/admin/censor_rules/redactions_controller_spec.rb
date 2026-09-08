require 'spec_helper'

RSpec.describe Admin::CensorRules::RedactionsController do
  before { basic_auth_login(@request) }

  describe 'GET #index' do
    let(:info_request) { FactoryBot.create(:info_request) }
    let(:rule) { FactoryBot.create(:global_censor_rule, text: 'secret') }

    render_views

    def index
      get :index, params: { request_id: info_request.id,
                            censor_rule_id: rule.id }
    end

    it 'returns a successful response' do
      index
      expect(response).to be_successful
    end

    it 'renders the index template' do
      index
      expect(response).to render_template('index')
    end

    it 'assigns the info request' do
      index
      expect(assigns[:info_request]).to eq(info_request)
    end

    it 'assigns the censor rule' do
      index
      expect(assigns[:censor_rule]).to eq(rule)
    end

    it 'assigns redactions scoped to the request' do
      om = info_request.outgoing_messages.first
      redaction = rule.redactions.create!(
        redactable: om, redacted_attribute: 'body'
      )

      other_request = FactoryBot.create(:info_request)
      other_om = other_request.outgoing_messages.first
      rule.redactions.create!(
        redactable: other_om, redacted_attribute: 'body'
      )

      index

      expect(assigns[:redactions]).to contain_exactly(redaction)
    end

    it 'orders redactions chronologically by the redactable record' do
      om = info_request.outgoing_messages.first
      om.update!(created_at: 2.days.ago)

      im = FactoryBot.create(:incoming_message, info_request: info_request,
                                                created_at: 1.day.ago)

      om_redaction = rule.redactions.create!(
        redactable: om, redacted_attribute: 'body'
      )

      im_redaction = rule.redactions.create!(
        redactable: im, redacted_attribute: 'from_name'
      )

      index

      expect(assigns[:redactions]).to eq([om_redaction, im_redaction])
    end
  end
end

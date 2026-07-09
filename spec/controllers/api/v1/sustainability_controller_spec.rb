require 'spec_helper'

RSpec.describe Api::V1::SustainabilityController, type: :controller do
  describe 'GET rate_limit' do
    it 'returns the rate-limiting information' do
      get :rate_limit
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json['tier']).to eq('anonymous')
      expect(json['limit']).to eq(10)
      expect(json['remaining']).to eq(10)
      expect(json['advisory_status']).to eq('nominal')
    end
  end

  describe 'GET bulk_export' do
    context 'without a token' do
      it 'returns unauthorized error' do
        get :bulk_export
        expect(response.status).to eq(401)
      end
    end

    context 'with a valid verified bot token' do
      let!(:info_request) { FactoryBot.create(:info_request) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('FYI_BOT_TOKEN').and_return('valid_secret_token')
        request.env['HTTP_X_FYI_BOT_TOKEN'] = 'valid_secret_token'
      end

      it 'returns 200 and streams NDJSON data' do
        get :bulk_export, params: { limit: 1 }

        expect(response.status).to eq(200)
        expect(response.headers['Content-Type']).to eq('application/x-ndjson')
        lines = response.body.split("\n")
        expect(lines.size).to eq(1)
        json = JSON.parse(lines.first)
        expect(json['title']).to eq(info_request.title)
        expect(json.keys).to contain_exactly(
          'id',
          'title',
          'url_title',
          'created_at',
          'updated_at',
          'status',
          'public_body_name',
          'public_body_url_name'
        )
      end

      it 'rejects invalid limit values' do
        get :bulk_export, params: { limit: 0 }

        expect(response.status).to eq(422)
      end

      it 'rejects invalid since values' do
        get :bulk_export, params: { since: 'not-a-date' }

        expect(response.status).to eq(422)
      end
    end
  end
end

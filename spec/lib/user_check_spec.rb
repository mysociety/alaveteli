require 'spec_helper'

RSpec.describe UserCheck do
  after { described_class.api_key = nil }

  describe '.enabled?' do
    it 'is true when a UserCheck API key is configured' do
      allow(AlaveteliConfiguration).
        to receive(:usercheck_api_key).and_return('api-key-123')
      expect(described_class.enabled?).to eq(true)
    end

    it 'is false when the UserCheck API key is blank' do
      allow(AlaveteliConfiguration).
        to receive(:usercheck_api_key).and_return('')
      expect(described_class.enabled?).to eq(false)
    end

    it 'allows the API key to be overridden for specs' do
      described_class.api_key = 'override-key'
      expect(described_class.enabled?).to eq(true)
    end
  end

  describe '.check_domain' do
    context 'when the integration is disabled' do
      before { described_class.api_key = '' }

      it 'returns a safe default result' do
        expect(described_class.check_domain('example.com')).
          to eq({ disposable: false, relay_domain: false })
      end

      it 'makes no HTTP requests' do
        described_class.check_domain('example.com')
        expect(WebMock).not_to have_requested(:get, /api\.usercheck\.com/)
      end
    end

    context 'when the integration is enabled' do
      let(:api_key) { 'api-key-123' }
      let(:domain) { 'example.com' }
      let(:api_url) { "https://api.usercheck.com/domain/#{domain}" }

      before { described_class.api_key = api_key }

      context 'with a blank domain' do
        it 'returns a safe default result for nil' do
          expect(described_class.check_domain(nil)).
            to eq({ disposable: false, relay_domain: false })
        end

        it 'returns a safe default result for an empty string' do
          expect(described_class.check_domain('')).
            to eq({ disposable: false, relay_domain: false })
        end

        it 'makes no HTTP requests' do
          described_class.check_domain(nil)
          described_class.check_domain('')
          expect(WebMock).not_to have_requested(:get, /api\.usercheck\.com/)
        end
      end

      context 'caching' do
        around do |example|
          original_cache = Rails.cache
          Rails.cache = ActiveSupport::Cache::MemoryStore.new
          example.call
          Rails.cache = original_cache
        end

        it 'caches successful results for 28 days keyed by domain' do
          stub_request(:get, api_url).
            to_return(status: 200, body: { 'disposable' => false }.to_json)

          expect(Rails.cache).to receive(:write).
            with("usercheck_domain_#{domain}",
                 hash_including(success: true),
                 expires_in: 28.days).
            and_call_original

          described_class.check_domain(domain)
        end

        it 'does not make a second HTTP request for a cached domain' do
          stub_request(:get, api_url).
            to_return(status: 200, body: { 'disposable' => false }.to_json)

          first_result = described_class.check_domain(domain)
          second_result = described_class.check_domain(domain)

          expect(WebMock).to have_requested(:get, api_url).once
          expect(second_result).to eq(first_result)
        end

        it 'does not cache failed results' do
          stub_request(:get, api_url).
            to_return(status: 500, body: '{"error": "server error"}')

          described_class.check_domain(domain)
          described_class.check_domain(domain)

          expect(WebMock).to have_requested(:get, api_url).twice
        end
      end

      context 'with a successful API response' do
        let(:api_response) do
          {
            'disposable' => true,
            'relay_domain' => false,
            'mx' => true,
            'status' => 200
          }
        end

        before do
          stub_request(:get, api_url).
            with(headers: { 'Authorization' => "Bearer #{api_key}" }).
            to_return(status: 200, body: api_response.to_json)
        end

        it 'returns the parsed API result' do
          expect(described_class.check_domain(domain)).to eq(
            success: true,
            disposable: true,
            relay_domain: false,
            mx_valid: true,
            raw_data: api_response
          )
        end
      end
      context 'with a 401 Unauthorized response' do
        before do
          stub_request(:get, api_url).
            to_return(status: 401, body: '{"error": "unauthorized"}')
        end

        it 'returns a failure result' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'Invalid API key')
        end

        it 'logs an error' do
          expect(Rails.logger).to receive(:error).
            with('UserCheck API: Invalid API key')
          described_class.check_domain(domain)
        end
      end

      context 'with a 429 Rate Limit response' do
        before do
          stub_request(:get, api_url).
            to_return(status: 429, body: '{"error": "rate limited"}')
        end

        it 'returns a failure result' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'Rate limit exceeded')
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).
            with('UserCheck API: Rate limit exceeded')
          described_class.check_domain(domain)
        end
      end

      context 'with another HTTP error response' do
        before do
          stub_request(:get, api_url).
            to_return(status: 500, body: '{"error": "server error"}')
        end

        it 'returns a failure result with the HTTP code' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'HTTP 500')
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).
            with('UserCheck API: Unexpected response 500')
          described_class.check_domain(domain)
        end
      end

      context 'with a timeout' do
        before { stub_request(:get, api_url).to_timeout }

        it 'returns a failure result' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'Timeout')
        end

        it 'logs a warning' do
          expect(Rails.logger).to receive(:warn).
            with(/UserCheck API: Timeout:/)
          described_class.check_domain(domain)
        end
      end

      context 'with an invalid JSON response' do
        before do
          stub_request(:get, api_url).
            to_return(status: 200, body: 'not json')
        end

        it 'returns a failure result' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'Invalid JSON response')
        end

        it 'logs an error' do
          expect(Rails.logger).to receive(:error).
            with(/UserCheck API: Invalid JSON response:/)
          described_class.check_domain(domain)
        end
      end

      context 'with a network error' do
        before do
          stub_request(:get, api_url).
            to_raise(SocketError.new('network unreachable'))
        end

        it 'returns a failure result with the error message' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'network unreachable')
        end

        it 'logs an error' do
          expect(Rails.logger).to receive(:error).
            with(/UserCheck API: Unexpected error:/)
          described_class.check_domain(domain)
        end
      end

      context 'with an SSL error' do
        before do
          stub_request(:get, api_url).
            to_raise(OpenSSL::SSL::SSLError.new('certificate verify failed'))
        end

        it 'returns a failure result with the error message' do
          expect(described_class.check_domain(domain)).
            to eq(success: false, error: 'certificate verify failed')
        end
      end
    end
  end

  describe '.register_scoring_methods!' do
    after { UserSpamScorer.reset }

    context 'when the integration is disabled' do
      before { described_class.api_key = '' }

      it 'registers no scoring methods' do
        described_class.register_scoring_methods!
        expect(UserSpamScorer.custom_scoring_methods).to be_empty
      end
    end

    context 'when the integration is enabled' do
      let(:user) { double('User', email_domain: 'example.com') }

      before do
        described_class.api_key = 'api-key-123'
        described_class.register_scoring_methods!
      end

      def registered_proc(method_name)
        UserSpamScorer.custom_scoring_methods[method_name][:proc]
      end

      it 'registers email_domain_is_disposable with a default score of 20' do
        expect(
          UserSpamScorer.custom_scoring_methods[
            :email_domain_is_disposable][:score]
        ).to eq(20)
      end

      it 'registers email_domain_is_relay with a default score of 10' do
        expect(
          UserSpamScorer.custom_scoring_methods[:email_domain_is_relay][:score]
        ).to eq(10)
      end

      it 'registers email_domain_invalid_mx with a default score of 5' do
        expect(
          UserSpamScorer.custom_scoring_methods[
            :email_domain_invalid_mx][:score]
        ).to eq(5)
      end

      it 'scores email_domain_is_disposable for a disposable domain' do
        allow(described_class).to receive(:check_domain).
          with('example.com').
          and_return(success: true, disposable: true, relay_domain: false,
                     mx_valid: true)

        expect(registered_proc(:email_domain_is_disposable).call(user)).
          to eq(true)
        expect(registered_proc(:email_domain_is_relay).call(user)).
          to eq(false)
      end

      it 'scores email_domain_is_relay for a relay domain' do
        allow(described_class).to receive(:check_domain).
          with('example.com').
          and_return(success: true, disposable: false, relay_domain: true,
                     mx_valid: true)

        expect(registered_proc(:email_domain_is_relay).call(user)).
          to eq(true)
        expect(registered_proc(:email_domain_is_disposable).call(user)).
          to eq(false)
      end

      it 'scores email_domain_invalid_mx for a domain with invalid MX' do
        allow(described_class).to receive(:check_domain).
          with('example.com').
          and_return(success: true, disposable: false, relay_domain: false,
                     mx_valid: false)

        expect(registered_proc(:email_domain_invalid_mx).call(user)).
          to eq(true)
      end

      it 'does not score email_domain_invalid_mx when MX is valid' do
        allow(described_class).to receive(:check_domain).
          with('example.com').
          and_return(success: true, disposable: false, relay_domain: false,
                     mx_valid: true)

        expect(registered_proc(:email_domain_invalid_mx).call(user)).
          to eq(false)
      end

      it 'scores nothing when the API request fails' do
        allow(described_class).to receive(:check_domain).
          with('example.com').
          and_return(success: false, error: 'Timeout')

        expect(registered_proc(:email_domain_is_disposable).call(user)).
          to be_falsey
        expect(registered_proc(:email_domain_is_relay).call(user)).
          to be_falsey
        expect(registered_proc(:email_domain_invalid_mx).call(user)).
          to be_falsey
      end
    end
  end
end

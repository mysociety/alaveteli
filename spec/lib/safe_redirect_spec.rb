require 'spec_helper'

RSpec.describe SafeRedirect do

  describe '.new' do

    it 'requires a redirect_parameter' do
      expect { subject }.to raise_error(ArgumentError)
    end

    it 'parses the redirect_parameter to a URI' do
      subject = described_class.new('/path')
      expect(subject.uri).to eq(URI.parse('/path'))
    end

    it 'rejects an invalid redirect_parameter' do
      expect { described_class.new(123) }.to raise_error(URI::InvalidURIError)
    end

  end

  describe '#path' do
    subject { described_class.new(redirect_param).path }

    context 'with a simple path' do
      let(:redirect_param) { '/request/the_cost_of_boring' }

      it 'returns the path' do
        expect(subject).to eq('/request/the_cost_of_boring')
      end

    end

    context 'with query parameters' do
      let(:redirect_param) { '/request/the_cost_of_boring?x=y&y=z' }

      it 'strips the query parameters' do
        expect(subject).to eq('/request/the_cost_of_boring')
      end

    end

    context 'with an anchor' do
      let(:redirect_param) { '/request/the_cost_of_boring#incoming-1' }

      it 'retains the anchor' do
        expect(subject).to eq('/request/the_cost_of_boring#incoming-1')
      end

    end

    context 'with query parameters and an anchor' do
      let(:redirect_param) { '/request/the_cost_of_boring?x=y&y=z#incoming-1' }

      it 'strips the query parameters and retains the anchor' do
        expect(subject).to eq('/request/the_cost_of_boring#incoming-1')
      end

    end

    context 'with a host component' do
      let(:redirect_param) { 'http://www.example.com/request/hello' }

      it 'strips the host' do
        expect(subject).to eq('/request/hello')
      end

    end

    context 'with an optional query' do
      subject { described_class.new(redirect_param).path(query: 'emergency=1') }

      let(:redirect_param) { '/request/hello' }

      it 'appends the query string' do
        expect(subject).to eq('/request/hello?emergency=1')
      end

    end

  end

end

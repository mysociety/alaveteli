require 'spec_helper'

RSpec.describe Search::Adapters::Xapian::Indexing do
  describe '.configure!' do
    it 'skips configuration when Xapian bindings are unavailable' do
      allow(ActsAsXapian).to receive(:bindings_available).and_return(false)
      expect(InfoRequestEvent).not_to receive(:acts_as_xapian)
      expect(PublicBody).not_to receive(:acts_as_xapian)
      expect(User).not_to receive(:acts_as_xapian)
      described_class.configure!
    end
  end

  describe '.configure_info_request_event!' do
    it 'configures texts for search_text_main and title' do
      options = InfoRequestEvent.xapian_options
      expect(options[:texts]).to eq([:search_text_main, :title])
    end

    it 'configures values for range search and sorting' do
      options = InfoRequestEvent.xapian_options
      expect(options[:values].map { |v| v[2] }).to include(
        'range_search', 'created_at', 'described_at',
        'request_collapse', 'request_title_collapse'
      )
    end

    it 'configures terms for filtering' do
      options = InfoRequestEvent.xapian_options
      term_prefixes = options[:terms].map { |t| t[2] }
      expect(term_prefixes).to include(
        'status', 'requested_by', 'requested_from',
        'variety', 'latest_status', 'filetype', 'tag'
      )
    end

    it 'configures eager loading' do
      options = InfoRequestEvent.xapian_options
      expect(options[:eager_load]).to include(:outgoing_message, :comment)
    end

    it 'applies the indexed_by_search? condition' do
      options = InfoRequestEvent.xapian_options
      expect(options[:if]).to eq(:indexed_by_search?)
    end
  end

  describe '.configure_public_body!' do
    it 'configures texts for name, short_name, and notes' do
      options = PublicBody.xapian_options
      expect(options[:texts]).to eq([:name, :short_name, :notes_as_string])
    end

    it 'configures terms for filtering' do
      options = PublicBody.xapian_options
      term_prefixes = options[:terms].map { |t| t[2] }
      expect(term_prefixes).to include('name', 'variety', 'tag')
    end

    it 'configures eager loading for translations' do
      options = PublicBody.xapian_options
      expect(options[:eager_load]).to eq([:translations])
    end
  end

  describe '.configure_user!' do
    it 'configures texts for name and about_me' do
      options = User.xapian_options
      expect(options[:texts]).to eq([:name, :about_me])
    end

    it 'configures variety term' do
      options = User.xapian_options
      term_prefixes = options[:terms].map { |t| t[2] }
      expect(term_prefixes).to eq(['variety'])
    end

    it 'applies the indexed_by_search? condition' do
      options = User.xapian_options
      expect(options[:if]).to eq(:indexed_by_search?)
    end
  end
end

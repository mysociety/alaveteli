# -*- encoding : utf-8 -*-
require 'spec_helper'

describe TypeaheadSearch do
  let(:options) { { :model => InfoRequestEvent } }

  describe "#initialize" do

    it 'assigns the query' do
      expect(TypeaheadSearch.new("chicken", options).query).to eq("chicken")
    end

    it 'assigns the model' do
      expect(TypeaheadSearch.new("chicken", options).model).to eq(InfoRequestEvent)
    end

    it 'assigns the page' do
      opts = options.merge(:page => 5)
      expect(TypeaheadSearch.new("chicken", opts).page).to eq(5)
    end

    it 'defaults to page 1 if no page value is passed' do
      expect(TypeaheadSearch.new("chicken", options).page).to eq(1)
    end

    it 'assigns per_page' do
      opts = options.merge(:per_page => 10)
      expect(TypeaheadSearch.new("chicken", opts).per_page).to eq(10)
    end

    it 'defaults to 25 per_page if no per_page value is passed' do
      expect(TypeaheadSearch.new("chicken", options).per_page).to eq(25)
    end

    it 'sets wildcard to true' do
      expect(TypeaheadSearch.new("chicken", options).wildcard).to be true
    end

    it 'sets run_search to true' do
      expect(TypeaheadSearch.new("chicken", options).run_search).to be true
    end

  end

  describe '#options' do

    it 'sets the offset based on the page and per_page settings' do
      opts = options.merge(:page => 2, :per_page => 10)
      expect(TypeaheadSearch.new("chicken", opts).options[:offset]).
        to eq(10)
    end

    it 'sets collapse_by_prefix to "request_collapse" for InfoRequestEvent queries' do
      expect(TypeaheadSearch.new("chicken", options).options[:collapse_by_prefix]).
        to eq("request_collapse")
    end

    it 'sets collapse_by_prefix to nil for PublicBody queries' do
      opts = options.merge(:model => PublicBody)
      expect(TypeaheadSearch.new("chicken", opts).options[:collapse_by_prefix]).
        to be nil
    end

    it 'sets the limit to the per_page setting' do
      opts = options.merge(:per_page => 10)
      expect(TypeaheadSearch.new("chicken", opts).options[:limit]).
        to eq(10)
    end

    it 'sets the model' do
      opts = options.merge(:model => PublicBody)
      expect(TypeaheadSearch.new("chicken", opts).options[:model]).
        to eq(PublicBody)
    end

    it 'sets wildcard to true by default' do
      expect(TypeaheadSearch.new("chicken", options).options[:wildcard]).
        to be true
    end

    it 'sets sort_by_prefix to nil' do
      expect(TypeaheadSearch.new("chicken", options).options[:sort_by_prefix]).
        to be nil
    end

    it 'sets sort_by_ascending to true' do
      expect(TypeaheadSearch.new("chicken", options).options[:sort_by_ascending]).
        to be true
    end

  end

  describe "#xapian_search" do

    before do
      get_fixtures_xapian_index
    end

    def search_info_requests(xapian_search)
      xapian_search.results.map { |result| result[:model].info_request }
    end

    def search_bodies(xapian_search)
      xapian_search.results.map { |result| result[:model] }
    end

    it "returns nil for the empty query string" do
      expect(TypeaheadSearch.new("", options).xapian_search).to be_nil
    end

    it "returns a search with results of the appropriate model type" do
      opts = options.merge(:model => PublicBody)
      search = TypeaheadSearch.new("geraldine", opts).xapian_search
      expect(search_bodies(search)).
        to match_array([public_bodies(:geraldine_public_body)])
    end

    it "returns results matching the given keywords in any of their locales" do
      # part of the spanish notes
      opts = options.merge(:model => PublicBody)
      search = TypeaheadSearch.new("baguette", opts).xapian_search
      expect(search_bodies(search)).
        to match_array([public_bodies(:humpadink_public_body)])
    end

    it "returns a search with results matching the given keyword" do
      search = TypeaheadSearch.new("chicken", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request)])
    end

    it "returns a search with results matching any of the given keywords" do
      search = TypeaheadSearch.new("money dog", options).xapian_search
      expect(search_info_requests(search)).to match_array([
        info_requests(:fancy_dog_request),
        info_requests(:naughty_chicken_request),
        info_requests(:another_boring_request),
      ])
    end

    it "returns nil for short words" do
      expect(TypeaheadSearch.new("a", options).xapian_search).to be_nil
    end

    it 'truncates the query string when it is too long' do
      search = TypeaheadSearch.new('a' * 500, options)
      search.xapian_search
      expect(search.query.bytesize).to eq(252)
    end

    it "returns a search with matches for complete words followed by a space" do
      search = TypeaheadSearch.new("chicken ", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request)])
    end


    it "returns a search with matches for the complete words in
        searches ending in short words" do
      search = TypeaheadSearch.new("chicken a", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request)])
    end


    it "returns a search with matches for the complete words and partial words in
        searches ending in longer words" do
      search = TypeaheadSearch.new("dog chick", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
                        info_requests(:fancy_dog_request)])
    end

    it "returns a search with partial matches for longer words" do
      search = TypeaheadSearch.new("chick", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request)])
    end

    it 'returns an "OR" search when query includes a standalone hyphen' do
      search = TypeaheadSearch.new("chicken - dog", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
               info_requests(:fancy_dog_request)])
    end

    it 'returns an "OR" search when query includes an ampersand' do
      search = TypeaheadSearch.new("chicken & dog", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
               info_requests(:fancy_dog_request)])
    end

    it 'returns an "OR" search when query includes a mismatched bracket' do
      search = TypeaheadSearch.new("chicken ( dog", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
               info_requests(:fancy_dog_request)])
    end

    it 'returns an "OR" search when query includes a standalone wildcard symbol' do
      search = TypeaheadSearch.new("chicken * dog", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
               info_requests(:fancy_dog_request)])
    end

    it 'returns an "OR" search when query includes a standalone tilde symbol' do
      search = TypeaheadSearch.new("chicken ~ dog", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:naughty_chicken_request),
               info_requests(:fancy_dog_request)])
    end

    it "returns a search excluding results from a valid negation operator" do
      search = TypeaheadSearch.new("dog -chicken", options).xapian_search
      expect(search_info_requests(search)).
        to match_array([info_requests(:fancy_dog_request)])
    end

    context 'when the exclude_tags option is used' do

      it "returns a search excluding results with those tags" do
        opts = options.merge( :model => PublicBody,
                              :exclude_tags => [ 'lonely_agency' ])
        search = TypeaheadSearch.new("lonely", opts).xapian_search
        expect(search.results).to match_array([])
      end

    end

    context 'when max wildcard limit is reached' do

      around do |example|
        ActsAsXapian.prepare_environment
        limit = ActsAsXapian.max_wildcard_expansion
        ActsAsXapian.max_wildcard_expansion = 1
        example.run
        ActsAsXapian.max_wildcard_expansion = limit
      end

      it 'fallbacks to an non-wildcard search' do
        search = TypeaheadSearch.new('dog', options)
        expect { search.xapian_search }.to(
          change(search, :wildcard).from(true).to(false)
        )
      end

    end
  end
end


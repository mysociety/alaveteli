# -*- encoding : utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'highlighting search results' do
  include HighlightHelper

  before do
    get_fixtures_xapian_index
  end

  it 'ignores stopwords' do
    phrase = 'department of humpadinking'
    search = ActsAsXapian::Search.new([PublicBody], phrase, :limit => 1)
    matches = search.words_to_highlight(:regex => true)
    expect(highlight_matches(phrase, matches)).to eq('<mark>department</mark> of <mark>humpadinking</mark>')
  end

  it 'ignores case' do
    search_phrase = 'department of humpadinking'
    search = ActsAsXapian::Search.new([PublicBody], search_phrase, :limit => 1)
    matches = search.words_to_highlight(:regex => true)
    expect(highlight_matches('Department of Humpadinking', matches)).to eq('<mark>Department</mark> of <mark>Humpadinking</mark>')
  end

  it 'highlights stemmed words' do
    phrase = 'department'
    search = ActsAsXapian::Search.new([PublicBody], phrase, :limit => 1)
    matches = search.words_to_highlight(:regex => true)

    expect(search.words_to_highlight(:regex => false)).to eq(['depart'])
    expect(highlight_matches(phrase, matches)).to eq('<mark>department</mark>')
  end

  it 'highlights stemmed words even if the stem is unhelpful' do
    # Stemming returns 'bore' as the word to highlight which can't be
    # matched in the original phrase.
    phrase = 'boring'
    search = ActsAsXapian::Search.new([PublicBody], phrase, :limit => 1)
    matches = search.words_to_highlight(:regex => true, :include_original => true)

    expect(highlight_matches(phrase, matches)).to eq('<mark>boring</mark>')
  end

  it 'handles macrons correctly' do
    phrase = 'Māori'

    search = ActsAsXapian::Search.new([PublicBody], phrase, :limit => 1)
    matches = search.words_to_highlight(:regex => true, :include_original => true)

    expect(highlight_matches(phrase, matches)).to eq('<mark>Māori</mark>')
  end

end

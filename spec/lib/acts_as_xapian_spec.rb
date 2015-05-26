# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# I would expect ActsAsXapian to have some tests under lib/acts_as_xapian, but
# it looks like this is not the case. Putting a test here instead.
describe ActsAsXapian::Search, "#words_to_highlight" do
    before(:each) do
         load_raw_emails_data
         get_fixtures_xapian_index
     end

    it "should return a list of words used in the search" do
        s = ActsAsXapian::Search.new([PublicBody], "albatross words", :limit => 100)
        s.words_to_highlight.should == ["albatross", "word"]
    end

    it "should remove any operators" do
        s = ActsAsXapian::Search.new([PublicBody], "albatross words tag:mice", :limit => 100)
        s.words_to_highlight.should == ["albatross", "word"]
    end

    it "should separate punctuation" do
        s = ActsAsXapian::Search.new([PublicBody], "The doctor's patient", :limit => 100)
        s.words_to_highlight.should == ["the", "doctor", "patient"].sort
    end

    it "should handle non-ascii characters" do
        s = ActsAsXapian::Search.new([PublicBody], "adatigénylés words tag:mice", :limit => 100)
        s.words_to_highlight.should == ["adatigénylé", "word"]
    end

    it "should ignore stopwords" do
        s = ActsAsXapian::Search.new([PublicBody], "department of humpadinking", :limit => 100)
        s.words_to_highlight.should_not include('of')
    end

    it "uses stemming" do
        s = ActsAsXapian::Search.new([PublicBody], 'department of humpadinking', :limit => 100)
        s.words_to_highlight.should == ["depart", "humpadink"]
    end

    it "doesn't stem proper nouns" do
        s = ActsAsXapian::Search.new([PublicBody], 'department of Humpadinking', :limit => 1)
        s.words_to_highlight.should == ["depart", "humpadinking"]
    end

    it "includes the original search terms if requested" do
        s = ActsAsXapian::Search.new([PublicBody], 'boring', :limit => 1)
        s.words_to_highlight(:include_original => true).should == ['bore', 'boring']
    end

    it "does not return duplicate terms" do
        s = ActsAsXapian::Search.new([PublicBody], 'boring boring', :limit => 1)
        s.words_to_highlight.should == ['bore']
    end

    context 'the :regex option' do

        it 'wraps each words in a regex that matches the full word' do
            expected = [/\b(albatross)\b/iu]
            s = ActsAsXapian::Search.new([PublicBody], 'Albatross', :limit => 1)
            s.words_to_highlight(:regex => true).should == expected
        end

        it 'wraps each stem in a regex' do
            expected = [/\b(depart)\w*\b/iu]
            s = ActsAsXapian::Search.new([PublicBody], 'department', :limit => 1)
            s.words_to_highlight(:regex => true).should == expected
        end

    end

end
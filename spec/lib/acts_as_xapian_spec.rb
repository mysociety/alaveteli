# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActsAsXapian::Search do

    describe "#words_to_highlight" do

        before :all do
            get_fixtures_xapian_index
            # make sure an index exists
            @alice = FactoryGirl.create(:public_body, :name => 'alice')
            update_xapian_index
        end

        after :all do
            @alice.destroy
            update_xapian_index
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

    describe :spelling_correction do

        before :all do
            get_fixtures_xapian_index
            @alice = FactoryGirl.create(:public_body, :name => 'alice')
            @bob = FactoryGirl.create(:public_body, :name => 'bôbby')
            update_xapian_index
        end

        after :all do
            @alice.destroy
            @bob.destroy
            update_xapian_index
        end

        it 'returns a UTF-8 encoded string' do
            s = ActsAsXapian::Search.new([PublicBody], "alece", :limit => 100)
            s.spelling_correction.should == "alice"
            if s.spelling_correction.respond_to? :encoding
                s.spelling_correction.encoding.to_s.should == 'UTF-8'
            end
        end

        it 'handles non-ASCII characters' do
            s = ActsAsXapian::Search.new([PublicBody], "bobby", :limit => 100)
            s.spelling_correction.should == "bôbby"
        end

    end

end
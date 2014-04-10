require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HighlightHelper do

    include HighlightHelper

    describe 'when highlighting text' do
      it 'should not highlight the middle of a word' do
        do_highlight("quack", %W(a), :highlighter => '*\1*').should == 'quack'
      end
      it 'should highlight a complete word' do
        do_highlight("quack a doodle", %W(a), :highlighter => '*\1*').should == 'quack *a* doodle'
      end
      it 'should work the same from highlight_words' do
        highlight_words("quack a doodle", %W(a), false).should == 'quack *a* doodle'
      end
    end

    describe 'when highlighting html' do
      it 'should not highlight the middle of a word' do
        highlight_words("quack", %W(a)).should == "quack"
      end
      it 'should highlight a complete word' do
        highlight_words("quack a doodle", %W(a)).should == 'quack <span class="highlight">a</span> doodle'
      end
    end
end

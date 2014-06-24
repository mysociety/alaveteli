require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HighlightHelper do

    include HighlightHelper

    describe 'when highlighting text' do
      it 'should not highlight the middle of a word' do
        do_highlight("quack", %w(ack), :highlighter => '*\1*').should == 'quack'
      end
      it 'should highlight a complete word' do
        do_highlight("quack ack doodle", %w(ack), :highlighter => '*\1*').should == 'quack *ack* doodle'
      end
      it 'should work the same from highlight_words' do
        highlight_words("quack ack doodle", %w(ack), false).should == 'quack *ack* doodle'
      end
      it 'should ignore stop works' do
        highlight_words("a about above moo across after", %w(a about above moo across after), false).should == "a about above *moo* across after"
      end
    end

    describe 'when highlighting html' do
      it 'should not highlight the middle of a word' do
        highlight_words("quack", %w(ack)).should == "quack"
      end
      it 'should highlight a complete word' do
        highlight_words("quack ack doodle", %w(ack)).should == 'quack <span class="highlight">ack</span> doodle'
      end
    end
end

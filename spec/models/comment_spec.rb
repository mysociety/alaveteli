require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Comment do

  describe :first_three_words do

    it 'returns the first three words of the comment body' do
      comment = Comment.new(:body => 'Hello there Alaveteli technical people')
      comment.first_three_words.should == 'Hello there Alaveteli'
    end

  end

end

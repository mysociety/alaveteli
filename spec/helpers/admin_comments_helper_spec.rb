require 'spec_helper'

describe AdminCommentsHelper do

  include AdminCommentsHelper

  describe '#comment_labels' do

    it 'adds no labels if the comment is not noteworthy' do
      expect(comment_labels(Comment.new)).to eq('')
    end

    it 'adds a hidden label if the comment is hidden' do
      comment = Comment.new(:visible => false)
      html = %q(<span class="label label-warning">hidden</span>)
      expect(comment_labels(comment)).to eq(html)
    end
  end

end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminHelper do

  include AdminHelper

  describe '#comment_visibility' do

    it 'shows the status of a visible comment' do
      comment = FactoryGirl.build(:visible_comment)
      expect(comment_visibility(comment)).to eq('Visible')
    end

    it 'shows the status of a hidden comment' do
      comment = FactoryGirl.build(:hidden_comment)
      expect(comment_visibility(comment)).to eq('Hidden')
    end

  end

end

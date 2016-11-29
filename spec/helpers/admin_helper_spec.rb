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

  describe '#sort_order_humanized' do

    it 'returns the humanized value if one is available' do
      expect(sort_order_humanized('name_asc')).to eq('Name ▲')
    end

    it 'returns the titleized value if a humanized value is not available' do
      expect(sort_order_humanized('blah_asc')).to eq('Blah Asc')
    end

    it 'accepts a Symbol argument' do
      expect(sort_order_humanized(:name_asc)).to eq('Name ▲')
    end

  end

end

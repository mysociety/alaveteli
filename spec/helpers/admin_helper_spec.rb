# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminHelper do

  include AdminHelper
  include ERB::Util

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

  describe '#comment_both_links' do

    let(:comment) { FactoryGirl.create(:comment) }

    it 'includes a link to the comment on the site' do
      expect(comment_both_links(comment)).to include(comment_path(comment))
    end

    it 'includes a link to admin edit page for the comment' do
      expect(comment_both_links(comment)).
        to include(edit_admin_comment_path(comment))
    end

  end

end

# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActionView::Helpers::TagHelper do
  include ActionView::Helpers::TagHelper

  describe '#content_tag' do
    it 'test_tag_does_not_honor_html_safe_double_quotes_as_attributes' do
      expect(content_tag('p', "content", title: '"'.html_safe)).
        to eq('<p title="&quot;">content</p>')
    end

    it 'test_data_tag_does_not_honor_html_safe_double_quotes_as_attributes' do
      expect(content_tag('p', "content", data: { title: '"'.html_safe })).
        to eq('<p data-title="&quot;">content</p>')
    end
  end

end

require 'spec_helper'

RSpec.describe Admin::TagHelper, type: :helper do
  include HasTagString

  describe '#render_tag' do
    let(:tag_without_value) do
      HasTagString::HasTagStringTag.new(
        model_type: 'PublicBody', name: 'foo'
      )
    end

    let(:tag_with_value) do
      HasTagString::HasTagStringTag.new(
        model_type: 'PublicBody', name: 'foo', value: 'bar'
      )
    end

    context 'tag with no value' do
      let(:record_tag) { tag_without_value }

      it 'renders the tag with a link' do
        expected = '<span class="label label-info tag">' \
                   '<a href="/admin/tags/foo?model_type=PublicBody">foo</a>' \
                   '</span>'
        expect(helper.render_tag(record_tag)).
          to eq(expected)
      end
    end

    context 'tag with a value' do
      let(:record_tag) { tag_with_value }

      it 'renders the tag and its value with links' do
        expected =
          '<span class="label label-info tag">' \
          '<a href="/admin/tags/foo?model_type=PublicBody">foo</a>:' \
          '<a href="/admin/tags/foo:bar?model_type=PublicBody">bar</a>' \
          '</span>'

        expect(helper.render_tag(record_tag)).
          to eq(expected)
      end
    end
  end
end

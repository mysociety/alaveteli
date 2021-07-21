require 'spec_helper'

RSpec.describe Admin::TagHelper, type: :helper do
  include HasTagString

  describe '#render_tag' do
    let(:tag_without_value) do
      HasTagString::HasTagStringTag.new(name: 'foo')
    end

    let(:tag_with_value) do
      HasTagString::HasTagStringTag.new(name: 'foo', value: 'bar')
    end

    context 'tag with no value' do
      let(:record_tag) { tag_without_value }
      let(:search_target) { nil }

      it 'renders the tag' do
        expect(helper.render_tag(record_tag, search_target: search_target)).
          to eq(%q(<span class="label label-info tag">foo</span>))
      end
    end

    context 'tag with a value' do
      let(:record_tag) { tag_with_value }
      let(:search_target) { nil }

      it 'renders the tag with its value' do
        expect(helper.render_tag(record_tag, search_target: search_target)).
          to eq(%q(<span class="label label-info tag">foo:bar</span>))
      end
    end

    context 'tag with no value and a search_target' do
      let(:record_tag) { tag_without_value }
      let(:search_target) { '/admin/some-index' }

      it 'renders the tag with a link to the search_target' do
        expected = '<span class="label label-info tag">' \
                   '<a href="/admin/some-index?tag=foo">foo</a>' \
                   '</span>'
        expect(helper.render_tag(record_tag, search_target: search_target)).
          to eq(expected)
      end
    end

    context 'tag with a value and a search_target' do
      let(:record_tag) { tag_with_value }
      let(:search_target) { '/admin/some-index' }

      it 'renders the tag and its value with links to the search_target' do
        expected = '<span class="label label-info tag">' \
                   '<a href="/admin/some-index?tag=foo">foo</a>:' \
                   '<a href="/admin/some-index?tag=foo%3Abar">bar</a>' \
                   '</span>'

        expect(helper.render_tag(record_tag, search_target: search_target)).
          to eq(expected)
      end
    end
  end
end

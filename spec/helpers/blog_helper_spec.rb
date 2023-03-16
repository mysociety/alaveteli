require 'spec_helper'

RSpec.describe BlogHelper do
  include BlogHelper

  describe '#blog_posts_for_taggable' do
    let(:taggable) { FactoryBot.create(:public_body, tag_string: 'foo') }

    subject(:posts) { blog_posts_for_taggable(taggable: taggable) }

    context 'when blog disabled' do
      before do
        allow(Blog).to receive(:enabled?).and_return(false)
      end

      let(:post) { FactoryBot.create(:blog_post, tag_string: 'foo') }

      it { is_expected.to eq([]) }
    end

    context 'when blog enabled taggable' do
      subject { blog_posts_for_taggable(taggable: taggable) }

      let(:post) { FactoryBot.create(:blog_post, tag_string: 'foo') }
      let(:other_post) { FactoryBot.create(:blog_post, tag_string: 'bar') }

      it { is_expected.to include(post) }
      it { is_expected.not_to include(other_post) }
    end

    context 'without limit' do
      before do
        4.times { FactoryBot.create(:blog_post, tag_string: 'foo') }
      end

      it 'limits to 3 posts' do
        expect(posts.count).to eq(3)
      end
    end

    context 'with limit' do
      subject(:posts) { blog_posts_for_taggable(taggable: taggable, limit: 1) }

      before do
        2.times { FactoryBot.create(:blog_post, tag_string: 'foo') }
      end

      it 'limits to specified number of posts' do
        expect(posts.count).to eq(1)
      end
    end
  end
end

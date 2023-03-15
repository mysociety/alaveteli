require 'spec_helper'

RSpec.describe Blog do
  describe '.enabled?' do
    subject { described_class.enabled? }

    context 'when feed is configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com')
      end

      it { is_expected.to eq(true) }
    end

    context 'when feed is not configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).and_return('')
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#posts' do
    let(:blog) { described_class.new }
    subject(:posts) { blog.posts }

    context 'when feed is fetched successfully' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com')

        allow(blog).to receive(:quietly_try_to_open).
          and_return(load_file_fixture('blog_feed.atom'))
      end

      it 'parses an item from an example feed' do
        expect(posts.count).to eq(1)
      end

      it 'returns Blog::Post objects' do
        expect(posts).to all be_a(Blog::Post)
      end

      it 'maps feed title to model title' do
        expect(posts.first.title).to eq('Example Post')
      end

      it 'maps feed link to model url' do
        expect(posts.first.url).to eq('http://www.example.com/example-post')
      end

      it 'maps feed to model data' do
        expect(posts.first.data).to include(
          'category' => ['FOI'],
          'creator' => ['Example Blogger'],
          'comments' => ['http://www.example.com/example-post#comments', '2'],
          'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000']
        )
      end

      it 'updates existing Blog::Post object when URL matches' do
        existing = FactoryBot.create(
          :blog_post, url: 'http://www.example.com/example-post'
        )
        expect { posts }.to change { existing.reload.title }.
          from('My fancy blog post - part 1').
          to('Example Post')
      end
    end

    context 'when feed returns an error' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com')
        stub_request(:get, %r|blog.example.com|).to_return(status: 500)
      end

      it 'should fail silently if the blog is returning an error' do
        expect(posts.count).to eq(0)
      end
    end
  end

  describe '#feeds' do
    let(:blog) { described_class.new }
    subject(:feeds) { blog.feeds }

    before do
      allow(AlaveteliConfiguration).to receive(:blog_feed).
        and_return('http://blog.example.com')
      allow(AlaveteliConfiguration).to receive(:site_name).
        and_return('My site')
    end

    it 'returns an array with a url (with lang query param) and title hash' do
      is_expected.to include(
        { url: 'http://blog.example.com?lang=en', title: 'My site blog' }
      )
    end
  end

  describe '#feed_url' do
    let(:blog) { described_class.new }
    subject(:feed_url) { blog.feed_url }

    context 'when feed is configured' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com')
      end

      it 'add lang query param correctly' do
        is_expected.to eq('http://blog.example.com?lang=en')
      end
    end

    context 'when feed is configured with existing query param' do
      before do
        allow(AlaveteliConfiguration).to receive(:blog_feed).
          and_return('http://blog.example.com?alt=rss')
      end

      it 'adds lang query param correctly' do
        is_expected.to eq('http://blog.example.com?alt=rss&lang=en')
      end
    end
  end
end

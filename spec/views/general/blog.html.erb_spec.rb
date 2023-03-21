require 'spec_helper'

RSpec.describe 'general/blog' do
  subject { rendered }

  before do
    assign :blog, double(posts: [double(blog_post_attributes)])
    assign :twitter_user, double.as_null_object
    assign :facebook_user, double.as_null_object
    render
  end

  context 'with a creator and date' do
    let(:blog_post_attributes) do
      {
        title: 'foo',
        url: 'https://www.example.com/foo',
        data: {
          'creator' => ['Bob'],
          'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000']
        }
      }
    end

    it { is_expected.to match(/Posted on.*April 01, 2013.*by Bob/) }
  end

  context 'with an author and date' do
    let(:blog_post_attributes) do
      {
        title: 'foo',
        url: 'https://www.example.com/foo',
        data: {
          'author' => ['Bob'],
          'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000']
        }
      }
    end

    it { is_expected.to match(/Posted on.*April 01, 2013.*by Bob/) }
  end

  context 'with a date and no author or creator' do
    let(:blog_post_attributes) do
      {
        title: 'foo',
        url: 'https://www.example.com/foo',
        data: {
          'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000']
        }
      }
    end

    it { is_expected.to match(/Posted on.*April 01, 2013/) }
  end
end

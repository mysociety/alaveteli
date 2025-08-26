require 'spec_helper'

RSpec.describe 'general/blog' do
  subject { rendered }

  before do
    assign :blog_items, blog_items
    assign :twitter_user, double.as_null_object
    assign :facebook_user, double.as_null_object
    render
  end

  context 'with a creator and date' do
    let(:blog_items) do
      [{ 'title' => 'foo',
         'link' => 'https://www.example.com/foo',
         'creator' => ['Bob'],
         'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000'] }]
    end

    it { is_expected.to match(/Posted on.*April 01, 2013.*by Bob/) }
  end

  context 'with an author and date' do
    let(:blog_items) do
      [{ 'title' => 'foo',
         'link' => 'https://www.example.com/foo',
         'author' => ['Bob'],
         'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000'] }]
    end

    it { is_expected.to match(/Posted on.*April 01, 2013.*by Bob/) }
  end

  context 'with a date and no author or creator' do
    let(:blog_items) do
      [{ 'title' => 'foo',
         'link' => 'https://www.example.com/foo',
         'pubDate' => ['Mon, 01 Apr 2013 19:26:08 +0000'] }]
    end

    it { is_expected.to match(/Posted on.*April 01, 2013/) }
  end
end

# == Schema Information
# Schema version: 20230314171033
#
# Table name: blog_posts
#
#  id         :bigint           not null, primary key
#  title      :string
#  url        :string
#  data       :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'spec_helper'

RSpec.describe Blog::Post, type: :model do
  let(:post) { FactoryBot.build(:blog_post) }

  describe 'validations' do
    specify { expect(post).to be_valid }

    it 'requires title' do
      post.title = nil
      expect(post).not_to be_valid
    end

    it 'requires url' do
      post.url = nil
      expect(post).not_to be_valid
    end

    it 'requires unique url' do
      FactoryBot.create(:blog_post, url: 'http://example.com/blog_post_1')
      post.url = 'http://example.com/blog_post_1'
      expect(post).not_to be_valid
    end
  end
end

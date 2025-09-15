# == Schema Information
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
FactoryBot.define do
  factory :blog_post, class: 'Blog::Post' do
    sequence(:title) { |n| "My fancy blog post - part #{n}" }
    sequence(:url) { |n| "http://example.com/blog_post_#{n}" }
  end
end

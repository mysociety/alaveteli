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
class Blog::Post < ApplicationRecord
  include Taggable

  def self.admin_title
    'Blog Post'
  end

  validates_presence_of :title, :url
  validates_uniqueness_of :url
end

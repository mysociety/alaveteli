##
# Helper methods for returning blog posts to be rendered
#
module BlogHelper
  def blog_posts_for_frontpage
    Blog::Post.order(id: :desc).limit(4)
  end

  def blog_posts_for_taggable(taggable:, limit: 3)
    return [] unless Blog.enabled?

    scope = Blog::Post.none
    taggable.tags.each { |t| scope = scope.or(Blog::Post.with_tag(t.name)) }
    scope.order(id: :desc).limit(limit)
  end
end

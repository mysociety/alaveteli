##
# Controller to manage tags for Blog::Post objects
#
class Admin::BlogPostsController < AdminController
  def index
    @blog_posts = Blog::Post.order(id: :desc).paginate(
      page: params[:page],
      per_page: 25
    )
  end
end

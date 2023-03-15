##
# Controller to manage tags for Blog::Post objects
#
class Admin::BlogPostsController < AdminController
  before_action :find_blog_post, only: [:edit, :update]

  def index
    @blog_posts = Blog::Post.order(id: :desc).paginate(
      page: params[:page],
      per_page: 25
    )
  end

  def edit
  end

  def update
    if @blog_post.update(blog_post_params)
      notice = 'Blog Post successfully updated.'
      redirect_to admin_blog_posts_path, notice: notice
    else
      render :edit
    end
  end

  private

  def find_blog_post
    @blog_post = Blog::Post.find(params[:id])
  end

  def blog_post_params
    {}
  end
end

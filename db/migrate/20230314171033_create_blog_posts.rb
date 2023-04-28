class CreateBlogPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :blog_posts do |t|
      t.string :title
      t.string :url
      t.jsonb :data

      t.timestamps
    end
  end
end

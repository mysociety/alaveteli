class CreatePostRedirects < ActiveRecord::Migration
  def self.up
    create_table :post_redirects do |t|
      t.column :token, :text
      t.column :uri, :text
      t.column :post_params_yaml, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :post_redirects
  end
end

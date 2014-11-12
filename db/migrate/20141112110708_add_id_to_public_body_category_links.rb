class AddIdToPublicBodyCategoryLinks < ActiveRecord::Migration
  # This join table was renamed and repurposed from one created by a
  # has_and_belongs_to_many association into one used by a
  # has_many, :through => association instead. The latter must have a single
  # primary key for cascaded deletes to work, it can't have a composite
  # primary key.

  def up
    # The old index was set up to be :primary, so we need to remove it before
    # we can add a different one
    remove_index :public_body_category_links, :name => "index_public_body_category_links_on_join_ids"
    # We add it back in, making it :unique instead
    add_index :public_body_category_links, [:public_body_category_id, :public_body_heading_id], :name => "index_public_body_category_links_on_join_ids", :unique => true
    # Now add a normal primary key column
    add_column :public_body_category_links, :id, :primary_key
  end

  def down
    # Remove the primary key column
    remove_column :public_body_category_links, :id
    # Go back to a composite primary key
    remove_index :public_body_category_links, :name => "index_public_body_category_links_on_join_ids"
    add_index :public_body_category_links, [:public_body_category_id, :public_body_heading_id], :name => "index_public_body_category_links_on_join_ids", :primary => true
  end
end

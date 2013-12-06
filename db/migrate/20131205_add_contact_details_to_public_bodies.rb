class AddContactDetailsToPublicBodies < ActiveRecord::Migration
  def up
    add_column :public_bodies, :contact_name, :text
    add_column :public_bodies, :contact_title, :text
    add_column :public_bodies, :street_address, :text
    add_column :public_bodies, :postal_address, :text
    add_column :public_bodies, :fax, :string
    add_column :public_bodies, :tel, :string
    add_column :public_bodies, :cel, :string
  end

  def down
    remove_column :public_bodies, :contact_name
    remove_column :public_bodies, :contact_title
    remove_column :public_bodies, :street_address
    remove_column :public_bodies, :postal_address
    remove_column :public_bodies, :fax
    remove_column :public_bodies, :tel
    remove_column :public_bodies, :cel
  end
end

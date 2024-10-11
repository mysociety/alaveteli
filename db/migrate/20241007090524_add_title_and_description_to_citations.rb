class AddTitleAndDescriptionToCitations < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :title, :string
    add_column :citations, :description, :text
  end
end

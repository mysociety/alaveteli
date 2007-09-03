class AddPublicBodyEditorNotes < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :last_edit_editor, :string
    add_column :public_bodies, :last_edit_comment, :string
    add_column :public_body_versions, :last_edit_editor, :string
    add_column :public_body_versions, :last_edit_comment, :string
  end

  def self.down
    remove_column :public_bodies, :last_edit_editor
    remove_column :public_bodies, :last_edit_comment
    remove_column :public_body_versions, :last_edit_editor
    remove_column :public_body_versions, :last_edit_comment
  end
end

# -*- encoding : utf-8 -*-
class SetPublicBodyTranslationDefaults < ActiveRecord::Migration
  def up
    change_column :public_body_translations,
                  :short_name, :text, :null => false, :default => ""
    change_column :public_body_translations,
                  :notes, :text, :null => false, :default => ""
    change_column :public_body_translations,
                  :publication_scheme, :text, :null => false, :default => ""
  end

  def down
    change_column :public_body_translations,
                  :short_name, :text, :null => false
    change_column :public_body_translations,
                  :notes, :text, :null => false
    change_column :public_body_translations,
                  :publication_scheme, :text, :null => false
  end
end

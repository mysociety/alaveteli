# -*- encoding : utf-8 -*-
class DropPublicBodyTranslatedColumns < ActiveRecord::Migration
  def change
    remove_column :public_bodies, :name, :text
    remove_column :public_bodies, :short_name, :text
    remove_column :public_bodies, :request_email, :text
    remove_column :public_bodies, :url_name, :text
    remove_column :public_bodies, :notes, :text
    remove_column :public_bodies, :first_letter, :text
    remove_column :public_bodies, :publication_scheme, :text
  end
end

# -*- encoding : utf-8 -*-
class DropPublicBodyTranslatedColumns < ActiveRecord::Migration
  def up
    remove_column :public_bodies, :name
    remove_column :public_bodies, :short_name
    remove_column :public_bodies, :request_email
    remove_column :public_bodies, :url_name
    remove_column :public_bodies, :notes
    remove_column :public_bodies, :first_letter
    remove_column :public_bodies, :publication_scheme
  end

  def down
    add_column :public_bodies, :name, :text
    add_column :public_bodies, :short_name, :text
    add_column :public_bodies, :request_email, :text
    add_column :public_bodies, :url_name, :text
    add_column :public_bodies, :notes, :text
    add_column :public_bodies, :first_letter, :text
    add_column :public_bodies, :publication_scheme, :text

    # Migrate the data back
    PublicBody.find_each do |pb|
      translated = pb.translation_for(I18n.default_locale)

      # Create a hash containing the translated column names and their values
      pb.translated_attribute_names.inject(fields_to_update={}) do |f, name|
        f.update({name.to_sym => translated[name.to_s]})
      end

      # Now, update the actual model's record with the hash
      PublicBody.where(:id => translated['id']).update_all(fields_to_update)
    end
  end
end

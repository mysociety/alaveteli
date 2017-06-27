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
    add_column :public_bodies, :first_letter, :string
    add_column :public_bodies, :publication_scheme, :text

    # Migrate the data back - wrapped in its own transaction so the data will
    # be updated before the constraints are reapplied
    PublicBody.transaction do
      PublicBody.find_each do |pb|
        translated = pb.translation_for(I18n.default_locale)

        # Create a hash containing the translated column names and their values
        pb.translated_attribute_names.inject(fields_to_update={}) do |f, name|
          f.update({name.to_sym => translated[name.to_s]})
        end

        # Now, update the actual model's record with the hash (using the
        # ActiveRecord::Relation method update_all to force the use of an
        # UPDATE statement rather than pb.update_atrributes which will
        # use the overridden attribute setters and update translations instead)
        PublicBody.where(:id => pb.id).update_all(fields_to_update)
      end
    end

    # Re-add the constraints
    change_column :public_bodies,
                  :name, :text, :null => false
    change_column :public_bodies,
                  :short_name, :text, :null => false, :default => ""
    change_column :public_bodies, :request_email, :text, :null => false
    change_column :public_bodies, :url_name, :text, :null => false
    change_column :public_bodies,
                  :notes, :text, :null => false, :default => ""
    change_column :public_bodies, :first_letter, :string, :null => false
    change_column :public_bodies,
                  :publication_scheme, :text, :null => false, :default => ""
  end
end

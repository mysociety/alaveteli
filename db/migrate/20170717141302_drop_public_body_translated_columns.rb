# -*- encoding : utf-8 -*-
class DropPublicBodyTranslatedColumns < ActiveRecord::Migration[4.2] # 4.1
  def up
    PublicBody.transaction do
      PublicBody.find_each do |record|
        translation =
          record.translation_for(AlaveteliLocalization.default_locale) ||
          record.translations.build(
            :locale => AlaveteliLocalization.default_locale
          )

        if translation.new_record?
          fields = record.translated_attribute_names
          fields.each do |attribute_name|
            translation[attribute_name] =
              record.read_attribute(attribute_name, :translated => false)
          end

          if translation.save
            puts "Created default locale translation for public body " \
                 "#{ record.id }"
          else
            puts "WARNING: Could not create default locale translation for " \
                 "public body #{ record.id }"
          end
        end
      end
    end

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
      PublicBody.find_each do |record|
        translated =
          record.translation_for(AlaveteliLocalization.default_locale)
        translated = record.translations.first unless translated.persisted?

        if translated.new_record? || translated.nil?
          puts "No translations for public body #{ record.id }"
          next
        end

        # Create a hash containing the translated column names and their values
        attr_names = record.translated_attribute_names
        attr_names.inject(fields_to_update={}) do |f, name|
          f.update({name.to_sym => translated[name.to_s]})
        end

        # Now, update the actual model's record with the hash (using the
        # ActiveRecord::Relation method update_all to force the use of an
        # UPDATE statement rather than record.update_attributes which will
        # use the overridden attribute setters and update translations instead)
        puts "Migrating default locale translation to public body #{record.id}"
        PublicBody.where(:id => record.id).update_all(fields_to_update)
      end
    end

    # Re-add the constraints
    change_column :public_bodies,
                  :name, :text, :null => false
    change_column :public_bodies, :request_email, :text, :null => false
    change_column :public_bodies, :url_name, :text, :null => false
    change_column :public_bodies, :first_letter, :string, :null => false
  end
end

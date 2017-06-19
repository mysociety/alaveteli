# -*- encoding : utf-8 -*-
class MigratePublicBodyData < ActiveRecord::Migration
  def up
    PublicBody.find_each do |record|
      translation = record.translation_for(I18n.default_locale) ||
        record.translations.build(:locale => I18n.default_locale)
      fields = record.translated_attributes
      fields.each do |attribute_name, attribute_type|
        translation[attribute_name] = record.
                                        read_attribute(attribute_name,
                                                       {:translated => false})
      end
      translation.save!
    end
  end

  def down
  end
end

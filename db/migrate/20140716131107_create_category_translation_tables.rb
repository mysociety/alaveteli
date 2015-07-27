# -*- encoding : utf-8 -*-
class CreateCategoryTranslationTables < ActiveRecord::Migration
  class PublicBodyCategory < ActiveRecord::Base
    translates :title, :description
  end
  class PublicBodyHeading < ActiveRecord::Base
    translates :name
  end
  def up
    default_locale = I18n.locale.to_s

    fields = {:title => :text,
              :description => :text}
    PublicBodyCategory.create_translation_table!(fields)

    # copy current values across to the default locale
    PublicBodyCategory.where(:locale => default_locale).each do |category|
      category.translated_attributes.each do |a, default|
        value = category.read_attribute(a)
        unless value.nil?
          category.send(:"#{a}=", value)
        end
      end
      category.save!
    end

    # copy current values across to the non-default locale(s)
    PublicBodyCategory.where('locale != ?', default_locale).each do |category|
      default_category = PublicBodyCategory.find_by_category_tag_and_locale(category.category_tag, default_locale)
      I18n.with_locale(category.locale) do
        category.translated_attributes.each do |a, default|
          value = category.read_attribute(a)
          unless value.nil?
            if default_category
              default_category.send(:"#{a}=", value)
            else
              category.send(:"#{a}=", value)
            end
          end
          category.delete if default_category
        end
      end
      if default_category
        default_category.save!
        category.delete
      else
        category.save!
      end
    end

    fields = { :name => :text }
    PublicBodyHeading.create_translation_table!(fields)

    # copy current values across to the default locale
    PublicBodyHeading.where(:locale => default_locale).each do |heading|
      heading.translated_attributes.each do |a, default|
        value = heading.read_attribute(a)
        unless value.nil?
          heading.send(:"#{a}=", value)
        end
      end
      heading.save!
    end

    # copy current values across to the non-default locale(s)
    PublicBodyHeading.where('locale != ?', default_locale).each do |heading|
      default_heading = PublicBodyHeading.find_by_name_and_locale(heading.name, default_locale)
      I18n.with_locale(heading.locale) do
        heading.translated_attributes.each do |a, default|
          value = heading.read_attribute(a)
          unless value.nil?
            if default_heading
              default_heading.send(:"#{a}=", value)
            else
              heading.send(:"#{a}=", value)
            end
          end
          heading.delete if default_heading
        end
      end
      if default_heading
        default_heading.save!
        heading.delete
      else
        heading.save!
      end
    end

    # finally, drop the old locale column from both tables
    remove_column :public_body_headings, :locale
    remove_column :public_body_categories, :locale
    remove_column :public_body_headings, :name
    remove_column :public_body_categories, :title
    remove_column :public_body_categories, :description

    # and set category_tag to be unique
    add_index :public_body_categories, :category_tag, :unique => true
  end

  def down
    # reinstate the columns
    add_column :public_body_categories, :locale, :string
    add_column :public_body_headings, :locale, :string
    add_column :public_body_headings, :name, :string
    add_column :public_body_categories, :title, :string
    add_column :public_body_categories, :description, :string

    # drop the index
    remove_index :public_body_categories, :category_tag

    # restore the data
    new_categories = []
    PublicBodyCategory.all.each do |category|
      category.locale = category.translation.locale.to_s
      I18n.available_locales.each do |locale|
        if locale.to_s != category.locale
          translation = category.translations.find_by_locale(locale)
          if translation
            new_cat = category.dup
            category.translated_attributes.each do |a, _|
              value = translation.read_attribute(a)
              new_cat.send(:"#{a}=", value)
            end
            new_cat.locale = locale.to_s
            new_categories << new_cat
          end
        else
          category.save!
        end
      end
    end
    new_categories.each do |cat|
      cat.save!
    end

    new_headings = []
    PublicBodyHeading.all.each do |heading|
      heading.locale = heading.translation.locale.to_s
      I18n.available_locales.each do |locale|
        if locale.to_s != heading.locale
          new_heading = heading.dup
          translation = heading.translations.find_by_locale(locale)
          if translation
            heading.translated_attributes.each do |a, _|
              value = translation.read_attribute(a)
              new_heading.send(:"#{a}=", value)
            end
            new_heading.locale = locale.to_s
            new_headings << new_heading
          end
        else
          heading.save!
        end
      end
    end
    new_headings.each do |heading|
      heading.save!
    end

    # drop the translation tables
    PublicBodyCategory.drop_translation_table!
    PublicBodyHeading.drop_translation_table!
  end
end

# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

class PublicBodyHeading < ActiveRecord::Base
    attr_accessible :locale, :name, :display_order, :translated_versions,
                    :translations_attributes

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_categories, :order => :category_display_order, :through => :public_body_category_links
    default_scope order('display_order ASC')

    translates :name
    accepts_nested_attributes_for :translations, :reject_if => :empty_translation_in_params?

    validates_uniqueness_of :name, :message => 'Name is already taken'
    validates_presence_of :name, :message => 'Name can\'t be blank'
    validates :display_order, :numericality => { :only_integer => true,
                                                 :message => 'Display order must be a number' }

    before_validation :on => :create do
        unless self.display_order
            self.display_order = PublicBodyHeading.next_display_order
        end
    end

    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        translations.find_by_locale(locale)
    end

    def translated_versions
        translations
    end

    def translated_versions=(translation_attrs)
        warn "[DEPRECATION] PublicBodyHeading#translated_versions= will be replaced " \
             "by PublicBodyHeading#translations_attributes= as of release 0.22"
        self.translations_attributes = translation_attrs
    end

    def ordered_translations
        translations.
          select { |t| I18n.available_locales.include?(t.locale) }.
            sort_by { |t| I18n.available_locales.index(t.locale) }
    end

    def build_all_translations
        I18n.available_locales.each do |locale|
            translations.build(:locale => locale) unless translations.detect{ |t| t.locale == locale }
        end
    end

    def add_category(category)
        unless public_body_categories.include?(category)
            public_body_categories << category
        end
    end

    def self.next_display_order
        if max = maximum(:display_order)
            max + 1
        else
            0
        end
    end

    private

    def empty_translation_in_params?(attributes)
        attrs_with_values = attributes.select do |key, value|
            value != '' and key.to_s != 'locale'
        end
        attrs_with_values.empty? 
    end

end

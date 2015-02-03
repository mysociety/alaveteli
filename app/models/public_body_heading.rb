# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer        not null, primary key
#  name          :text           not null
#  display_order :integer
#

class PublicBodyHeading < ActiveRecord::Base
    attr_accessible :name, :display_order, :translated_versions,
                    :translations_attributes

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_categories, :order => :category_display_order, :through => :public_body_category_links
    default_scope order('display_order ASC')

    translates :name
    accepts_nested_attributes_for :translations

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

    def translations_attributes=(translation_attrs)
        def empty_translation?(attrs)
            attrs_with_values = attrs.select{ |key, value| value != '' and key.to_s != 'locale' }
            attrs_with_values.empty?
        end
        if translation_attrs.respond_to? :each_value    # Hash => updating
            translation_attrs.each_value do |attrs|
                next if empty_translation?(attrs)
                t = translation_for(attrs[:locale]) || PublicBodyHeading::Translation.new
                t.attributes = attrs
                t.save!
            end
        else                                            # Array => creating
            warn "[DEPRECATION] PublicBodyHeading#translations_attributes= " \
                 "will no longer accept an Array as of release 0.22. " \
                 "Use Hash arguments instead. See " \
                 "spec/models/public_body_heading_spec.rb and " \
                 "app/views/admin_public_body_headings/_form.html.erb for more " \
                 "details."
            translation_attrs.each do |attrs|
                next if empty_translation?(attrs)
                new_translation = PublicBodyHeading::Translation.new(attrs)
                translations << new_translation
            end
        end
    end

    def translated_versions=(translation_attrs)
        warn "[DEPRECATION] PublicBodyHeading#translated_versions= will be replaced " \
             "by PublicBodyHeading#translations_attributes= as of release 0.22"
        self.translations_attributes = translation_attrs
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

end

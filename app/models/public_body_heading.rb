# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer        not null, primary key
#  name          :text           not null
#  display_order :integer
#

class PublicBodyHeading < ActiveRecord::Base
    attr_accessible :name, :display_order, :translated_versions

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_categories, :order => :category_display_order, :through => :public_body_category_links
    default_scope order('display_order ASC')

    translates :name

    validates_uniqueness_of :name, :message => N_('Name is already taken')
    validates_presence_of :name, :message => N_('Name can\'t be blank')
    validates :display_order, :numericality => { :only_integer => true,
                                                 :message => N_('Display order must be a number') }

    before_validation :on => :create do
        unless self.display_order
            self.display_order = PublicBodyHeading.next_display_order
        end
    end

    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        self.translations.find_by_locale(locale)
    end

    def translated_versions
        translations
    end

    def translated_versions=(translation_attrs)
        def skip?(attrs)
            valueless = attrs.inject({}) { |h, (k, v)| h[k] = v if v != '' and k != 'locale'; h } # because we want to fall back to alternative translations where there are empty values
            return valueless.length == 0
        end

        if translation_attrs.respond_to? :each_value    # Hash => updating
            translation_attrs.each_value do |attrs|
                next if skip?(attrs)
                t = translation_for(attrs[:locale]) || PublicBodyHeading::Translation.new
                t.attributes = attrs
                t.save!
            end
        else                                            # Array => creating
            translation_attrs.each do |attrs|
                next if skip?(attrs)
                new_translation = PublicBodyHeading::Translation.new(attrs)
                translations << new_translation
            end
        end
    end

    def PublicBodyHeading.next_display_order
        if max = maximum(:display_order)
            max + 1
        else
            0
        end
    end
end

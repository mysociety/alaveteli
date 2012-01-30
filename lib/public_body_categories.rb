# lib/public_body_categories.rb:
# Categorisations of public bodies.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_categories.rb,v 1.1 2009-09-14 14:45:48 francis Exp $

class PublicBodyCategories
    
    attr_reader :with_description, :with_headings, :tags, :by_tag, :singular_by_tag
    
    def initialize(categories)
        @with_headings = categories
        # Arranged in different ways for different sorts of displaying
        @with_description = @with_headings.select() { |a| a.instance_of?(Array) }
        @tags = @with_description.map() { |a| a[0] }
        @by_tag = Hash[*@with_description.map() { |a| a[0..1] }.flatten]
        @singular_by_tag = Hash[*@with_description.map() { |a| [a[0],a[2]] }.flatten]        
    end

    def PublicBodyCategories.get
        load_categories if @@CATEGORIES.empty?
        @@CATEGORIES[I18n.locale.to_s] || @@CATEGORIES[I18n.default_locale.to_s] || PublicBodyCategories.new([])
    end

    # Called from the data files themselves
    def PublicBodyCategories.add(locale, categories)
        @@CATEGORIES[locale.to_s] = PublicBodyCategories.new(categories)
    end
    
    private
    @@CATEGORIES = {}
    
    def PublicBodyCategories.load_categories()
        I18n.available_locales.each do |locale|
            begin
                load "public_body_categories_#{locale}.rb"
            rescue MissingSourceFile
            end
        end
    end
end

module CategoryAndHeadingMigrator

    # This module migrates data from public_body_categories_[locale].rb files
    # into PublicBodyHeading and PublicBodyCategory models

    # Load all the data from public_body_categories_[locale].rb files.
    def self.migrate_categories_and_headings
        if PublicBodyCategory.count > 0
            puts "PublicBodyCategories exist already, not migrating."
        else
            @first_locale = true
            I18n.available_locales.each do |locale|
                begin
                    load "public_body_categories_#{locale}.rb"
                rescue MissingSourceFile
                end
                @first_locale = false
            end
        end
    end

    # Load the categories and headings for a locale
    def self.add_categories_and_headings_from_list(locale, data_list)
        # set the counter for headings loaded from this locale
        @@locale_heading_display_order = 0
        current_heading = nil
        data_list.each do |list_item|
            if list_item.is_a?(Array)
                # item is list of category data
                add_category(list_item, current_heading, locale)
            else
                # item is heading name
                current_heading = add_heading(list_item, locale, @first_locale)
            end
        end
    end

    def self.add_category(category_data, heading, locale)
        tag, title, description = category_data
        category = PublicBodyCategory.find_by_category_tag(tag)
        if category
            add_category_in_locale(category, title, description, locale)
        else
            category = PublicBodyCategory.create(:category_tag => tag,
                                                 :title => title,
                                                 :description => description)

            # add the translation if this is not the default locale
            # (occurs when a category is not defined in default locale)
            unless category.translations.map { |t| t.locale }.include?(locale)
                add_category_in_locale(category, title, description, locale)
            end
        end
        heading.add_category(category)
    end

    def self.add_category_in_locale(category, title, description, locale)
        I18n.with_locale(locale) do
            category.title = title
            category.description = description
            category.save
        end
    end

    def self.add_heading(name, locale, first_locale)
        heading = nil
        I18n.with_locale(locale) do
            heading = PublicBodyHeading.find_by_name(name)
        end
        # For multi-locale installs, we assume that all public_body_[locale].rb files
        # use the same headings in the same order, so we add translations to the heading
        # that was in the same position in the list loaded from other public_body_[locale].rb
        # files.
        if heading.nil? && !@first_locale
            heading = PublicBodyHeading.where(:display_order => @@locale_heading_display_order).first
        end

        if heading
            I18n.with_locale(locale) do
                heading.name = name
                heading.save
            end
        else
            I18n.with_locale(locale) do
                heading = PublicBodyHeading.create(:name => name)
            end
        end
        @@locale_heading_display_order += 1
        heading
    end
end

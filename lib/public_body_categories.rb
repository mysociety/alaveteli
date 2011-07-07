# lib/public_body_categories.rb:
# Categorisations of public bodies.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_categories.rb,v 1.1 2009-09-14 14:45:48 francis Exp $

module PublicBodyCategories

    CATEGORIES_WITH_HEADINGS = []

    # Arranged in different ways for different sorts of displaying
    CATEGORIES_WITH_DESCRIPTION = CATEGORIES_WITH_HEADINGS.select() { |a| a.instance_of?(Array) }
    CATEGORIES = CATEGORIES_WITH_DESCRIPTION.map() { |a| a[0] }
    CATEGORIES_BY_TAG = Hash[*CATEGORIES_WITH_DESCRIPTION.map() { |a| a[0..1] }.flatten]
    CATEGORY_SINGULAR_BY_TAG = Hash[*CATEGORIES_WITH_DESCRIPTION.map() { |a| [a[0],a[2]] }.flatten]
end


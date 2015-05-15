# -*- encoding : utf-8 -*-
# replicate original file-based PublicBodyCategories functionality
class PublicBodyCategory::CategoryCollection
    include Enumerable
    extend Forwardable
    def_delegators :@categories, :each, :<<

    def initialize
        @categories = []
    end

    def with_headings
        @categories
    end

    def with_description
        @categories.select() { |a| a.instance_of?(Array) }
    end

    def tags
        tags = with_description.map() { |a| a[0] }
    end

    def by_tag
        Hash[*with_description.map() { |a| a[0..1] }.flatten]
    end

    def singular_by_tag
        Hash[*with_description.map() { |a| [a[0],a[2]] }.flatten]
    end

    def by_heading
        output = {}
        heading = nil
        @categories.each do |row|
            if row.is_a?(Array)
                output[heading] << row[0]
            else
                heading = row
                output[heading] = []
            end
        end
        output
    end

    def headings
        output = []
        @categories.each do |row|
            unless row.is_a?(Array)
                output << row
            end
        end
        output
    end
end

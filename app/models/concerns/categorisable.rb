##
# Module concern with methods to help categorise records
#
module Categorisable
  extend ActiveSupport::Concern

  def self.models
    @models ||= []
  end

  included do
    Categorisable.models << self

    def self.category_root
      Category.roots.find_or_create_by(title: name)
    end

    def self.categories
      category_root.tree
    end
  end
end

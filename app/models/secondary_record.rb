class SecondaryRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :secondary, reading: :secondary }

  include ConfigHelper

  include AdminColumn

  def self.admin_title
    name
  end
end

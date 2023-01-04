class ApplicationRecord < ActiveRecord::Base
  include ConfigHelper

  include AdminColumn

  self.abstract_class = true

  def self.admin_title
    name
  end
end

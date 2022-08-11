class ApplicationRecord < ActiveRecord::Base
  include ConfigHelper

  self.abstract_class = true

  def self.admin_title
    name
  end
end

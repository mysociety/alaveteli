class ApplicationRecord < ActiveRecord::Base
  include ConfigHelper

  self.abstract_class = true
end

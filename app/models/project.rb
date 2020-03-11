##
# A model to represent a FOI project which many contributors work on multiple
# info requests.
#
class Project < ApplicationRecord
  validates :title, presence: true
end

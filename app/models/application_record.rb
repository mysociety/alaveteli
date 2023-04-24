class ApplicationRecord < ActiveRecord::Base
  include ConfigHelper

  include AdminColumn

  self.abstract_class = true

  def self.admin_title
    name
  end

  def self.created_between(from:, to:)
    from = Time.zone.parse(from).at_beginning_of_day
    to = Time.zone.parse(to).at_end_of_day

    where(created_at: from..to)
  end
end

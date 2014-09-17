class WidgetVote < ActiveRecord::Base
  belongs_to :info_request
  validates :info_request, :presence => true

  attr_accessible :cookie
  validates :cookie, :length => { :is => 20 }
end

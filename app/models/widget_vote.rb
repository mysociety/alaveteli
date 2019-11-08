# == Schema Information
# Schema version: 20220322100510
#
# Table name: widget_votes
#
#  id              :bigint           not null, primary key
#  cookie          :string
#  info_request_id :bigint           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class WidgetVote < ApplicationRecord
  belongs_to :info_request,
             :inverse_of => :widget_votes

  validates :info_request, :presence => true
  validates :cookie, length: { is: 20 }
  validates :cookie, uniqueness: { scope: :info_request_id }
end

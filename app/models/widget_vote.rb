# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: widget_votes
#
#  id              :integer          not null, primary key
#  cookie          :string(255)
#  info_request_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class WidgetVote < ActiveRecord::Base
  belongs_to :info_request
  validates :info_request, :presence => true

  validates :cookie, length: { is: 20 }
  validates :cookie, uniqueness: { scope: :info_request_id }
end

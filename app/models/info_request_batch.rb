# == Schema Information
# Schema version: 20131024114346
#
# Table name: info_request_batches
#
#  id         :integer          not null, primary key
#  title      :text             not null
#  user_id    :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

class InfoRequestBatch < ActiveRecord::Base
    has_many :info_requests
    belongs_to :user

    validates_presence_of :user
    validates_presence_of :title

end

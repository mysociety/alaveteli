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
    validates_presence_of :body

    #  When constructing a new batch, use this to check user hasn't double submitted.
    def InfoRequestBatch.find_existing(user, title, body, public_body_ids)
        find(:first, :conditions => ['info_request_batches.user_id = ?
                                      AND info_request_batches.title = ?
                                      AND body = ?
                                      AND info_requests.public_body_id in (?)',
                                      user, title, body, public_body_ids],
                     :include => :info_requests)
    end


end

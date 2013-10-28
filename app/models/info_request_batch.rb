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


    def InfoRequestBatch.create_batch!(info_request_params, outgoing_message_params, public_body_ids, user)
        info_request_batch = InfoRequestBatch.create!(:title => info_request_params[:title],
                                                      :body => outgoing_message_params[:body],
                                                      :user => user)
       public_bodies = PublicBody.where({:id => public_body_ids}).all
       unrequestable = []
       public_bodies.each do |public_body|
           if public_body.is_requestable?
               info_request = InfoRequest.create_from_attributes(info_request_params,
                                                                 outgoing_message_params,
                                                                 user)
               info_request.public_body_id = public_body.id
               info_request.info_request_batch = info_request_batch
               info_request.save!
               info_request.outgoing_messages.first.send_message
           else
                unrequestable << public_body
           end
       end
       return {:batch => info_request_batch, :unrequestable => unrequestable}
    end
end

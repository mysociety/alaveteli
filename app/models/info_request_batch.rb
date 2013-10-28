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

    # Create a batch of information requests, returning the batch, and a list of public bodies
    # that are unrequestable from the initial list of public body ids passed.
    def InfoRequestBatch.create_batch!(info_request_params, outgoing_message_params, public_body_ids, user)
        info_request_batch = nil
        unrequestable = []
        created = []
        public_bodies = PublicBody.where({:id => public_body_ids}).all
        ActiveRecord::Base.transaction do
            info_request_batch = InfoRequestBatch.create!(:title => info_request_params[:title],
                                                          :body => outgoing_message_params[:body],
                                                          :user => user)
            public_bodies.each do |public_body|
                if public_body.is_requestable?
                    created << info_request_batch.create_request!(public_body,
                                                                  info_request_params,
                                                                  outgoing_message_params,
                                                                  user)
                else
                    unrequestable << public_body
                end
            end
        end
        created.each{ |info_request| info_request.outgoing_messages.first.send_message }
        return {:batch => info_request_batch, :unrequestable => unrequestable}
    end

    # Create and send an FOI request to a public body
    def create_request!(public_body, info_request_params, outgoing_message_params, user)
        body = OutgoingMessage.fill_in_salutation(outgoing_message_params[:body], public_body)
        info_request = InfoRequest.create_from_attributes(info_request_params,
                                                          outgoing_message_params.merge(:body => body),
                                                          user)
        info_request.public_body_id = public_body.id
        info_request.info_request_batch = self
        info_request.save!
        info_request
    end
end

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
    has_and_belongs_to_many :public_bodies

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

    # Create a batch of information requests, returning a list of public bodies
    # that are unrequestable from the initial list of public body ids passed.
    def create_batch!
        unrequestable = []
        created = []
        ActiveRecord::Base.transaction do
            public_bodies.each do |public_body|
                if public_body.is_requestable?
                    created << create_request!(public_body)
                else
                    unrequestable << public_body
                end
            end
        end
        created.each{ |info_request| info_request.outgoing_messages.first.send_message }
        return {:unrequestable => unrequestable}
    end

    # Create and send an FOI request to a public body
    def create_request!(public_body)
        body = OutgoingMessage.fill_in_salutation(self.body, public_body)
        info_request = InfoRequest.create_from_attributes({:title => self.title},
                                                          {:body => body},
                                                          self.user)
        info_request.public_body_id = public_body.id
        info_request.info_request_batch = self
        info_request.save!
        info_request
    end
end

# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_batches
#
#  id         :integer          not null, primary key
#  title      :text             not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  body       :text
#  sent_at    :datetime
#

class InfoRequestBatch < ActiveRecord::Base
    has_many :info_requests
    belongs_to :user
    has_and_belongs_to_many :public_bodies

    validates_presence_of :user
    validates_presence_of :title
    validates_presence_of :body

    #  When constructing a new batch, use this to check user hasn't double submitted.
    def self.find_existing(user, title, body, public_body_ids)
        find(:first, :conditions => ['user_id = ?
                                      AND title = ?
                                      AND body = ?
                                      AND info_request_batches_public_bodies.public_body_id in (?)',
                                      user, title, body, public_body_ids],
                     :include => :public_bodies)
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
            self.sent_at = Time.now
            self.save!
        end
        created.each do |info_request|
            outgoing_message = info_request.outgoing_messages.first
            
            outgoing_message.sendable?
            mail_message = OutgoingMailer.initial_request(outgoing_message.info_request, outgoing_message).deliver
            outgoing_message.record_email_delivery(mail_message.to_addrs.join(', '), mail_message.message_id)
        end

        return unrequestable
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

    def self.send_batches
        find_each(:conditions => "sent_at IS NULL") do |info_request_batch|
            unrequestable = info_request_batch.create_batch!
            mail_message = InfoRequestBatchMailer.batch_sent(info_request_batch,
                                                             unrequestable,
                                                             info_request_batch.user).deliver
        end
    end
end

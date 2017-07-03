# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20170328100359
#
# Table name: info_request_batches
#
#  id               :integer          not null, primary key
#  title            :text             not null
#  user_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  sent_at          :datetime
#  embargo_duration :string(255)
#

class InfoRequestBatch < ActiveRecord::Base
  include AlaveteliPro::RequestSummaries

  has_many :info_requests
  belongs_to :user, :counter_cache => true
  has_and_belongs_to_many :public_bodies, -> { reorder('public_bodies.name asc') }

  validates_presence_of :user
  validates_presence_of :title
  validates_presence_of :body

  #  When constructing a new batch, use this to check user hasn't double submitted.
  def self.find_existing(user, title, body, public_body_ids)
    conditions = {
      :user_id => user,
      :title => title,
      :body => body,
      :info_request_batches_public_bodies => {
        :public_body_id => public_body_ids
      }
    }

    includes(:public_bodies).where(conditions).references(:public_bodies).first
  end

  # Create a new batch from the supplied draft version
  def self.from_draft(draft)
    self.new(:user => draft.user,
             :public_bodies => draft.public_bodies,
             :title => draft.title,
             :body => draft.body,
             :embargo_duration => draft.embargo_duration)
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
      self.sent_at = Time.zone.now
      self.save!
    end
    created.each do |info_request|
      outgoing_message = info_request.outgoing_messages.first

      outgoing_message.sendable?
      mail_message = OutgoingMailer.
        initial_request(
          outgoing_message.info_request,
          outgoing_message
        ).deliver_now
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
    unless self.embargo_duration.blank?
      info_request.embargo = AlaveteliPro::Embargo.create(
        :info_request => info_request,
        :embargo_duration => self.embargo_duration
      )
    end
    info_request.save!
    info_request
  end

  def self.send_batches
    where(:sent_at => nil).find_each do |info_request_batch|
      unrequestable = info_request_batch.create_batch!
      mail_message = InfoRequestBatchMailer.
                       batch_sent(
                         info_request_batch,
                         unrequestable,
                         info_request_batch.user
                       ).deliver_now
    end
  end

  # Build an InfoRequest object which is an example of this batch.
  def example_request
    public_body = self.public_bodies.first
    body = OutgoingMessage.fill_in_salutation(self.body, public_body)
    info_request = InfoRequest.create_from_attributes(
      { :title => self.title, :public_body => public_body },
      { :body => body },
      self.user
    )
    unless self.embargo_duration.blank?
      info_request.embargo = AlaveteliPro::Embargo.new(
        :info_request => info_request,
        :embargo_duration => self.embargo_duration
      )
    end
    info_request
  end

  # Do any of the requests in this batch have an embargo which is expiring
  # soon?
  #
  # Returns boolean
  def embargo_expiring?
    info_requests.embargo_expiring.any?
  end

  # What phases are the requests in this batch in
  #
  # Returns unique array of symbols representing phases from InfoRequest::State
  def request_phases
    phases = info_requests.collect do |ir|
      if ir.last_event_forming_initial_request_id.nil?
        :awaiting_response
      else
        ir.state.phase
      end
    end
    phases.uniq
  end

  # Summarise the phases requests are in into three groups:
  # in progress, action needed, complete and provide a count of the number of
  # requests in each group.
  #
  # Returns hash of string group names mapped to an integer
  def request_phases_summary
    {
      :in_progress => {
        :label => _('In progress'),
        :count => self.info_requests.in_progress.count
      },
      :action_needed => {
        :label => _('Action needed'),
        :count => self.info_requests.action_needed.count
      },
      :complete => {
        :label => _('Complete'),
        :count => self.info_requests.complete.count
      },
      :other => {
        :label => _('Other'),
        :count => self.info_requests.other.count
      }
    }
  end

  # @see RequestSummaries#request_summary_body
  def request_summary_body
    self.body
  end

  # @see RequestSummaries#request_summary_public_body_names
  def request_summary_public_body_names
    self.public_bodies.pluck(:name).join(" ")
  end

  # @see RequestSummaries#request_summary_categories
  def request_summary_categories
    categories = []
    if self.embargo_expiring?
      categories << AlaveteliPro::RequestSummaryCategory.embargo_expiring
    end
    if self.sent_at
      phase_slugs = self.request_phases.map(&:to_s).uniq
      phases = AlaveteliPro::RequestSummaryCategory.where(slug: phase_slugs)
      categories.concat phases
    else
      # A batch info request which hasn't been sent yet won't show up in the
      # list unless we give it some kind of category, so we fake an awaiting
      # response one
      categories << AlaveteliPro::RequestSummaryCategory.awaiting_response
    end
    categories
  end
end

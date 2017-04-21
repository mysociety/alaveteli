# == Schema Information
# Schema version: 20170411113908
#
# Table name: request_summaries
#
#  id                :integer          not null, primary key
#  title             :text
#  body              :text
#  public_body_names :text
#  summarisable_id   :integer
#  summarisable_type :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class AlaveteliPro::RequestSummary < ActiveRecord::Base
  belongs_to :summarisable, polymorphic: true
  belongs_to :user
  has_and_belongs_to_many :request_summary_categories,
                          :class_name => "AlaveteliPro::RequestSummaryCategory"

  validates_presence_of :summarisable

  ALLOWED_REQUEST_CLASSES = ["InfoRequest",
                             "DraftInfoRequest",
                             "InfoRequestBatch",
                             "AlaveteliPro::DraftInfoRequestBatch"].freeze

  def self.create_or_update_from(request)
    unless ALLOWED_REQUEST_CLASSES.include?(request.class.name)
      raise ArgumentError.new("Can't create a RequestSummary from " \
                              "#{request.class.name} instances. Only " \
                              "#{ALLOWED_REQUEST_CLASSES} are allowed.")
    end
    if request.request_summary
      request.request_summary.update_from_request
      request.request_summary
    else
      self.create_from(request)
    end
  end

  def update_from_request
    update_attributes(self.class.attributes_from_request(self.summarisable))
  end

  private

  def self.create_from(request)
    self.create(attributes_from_request(request))
  end

  def self.attributes_from_request(request)
    {
      title: request.title,
      body: extract_request_body(request),
      public_body_names: extract_request_public_body_names(request),
      summarisable: request,
      user: request.user,
      request_summary_categories: self.extract_categories(request)
    }
  end

  def self.extract_request_body(request)
    if request.class == InfoRequest
      request.outgoing_messages.any? ? request.outgoing_messages.first.body : ""
    else
      request.body
    end
  end

  def self.extract_request_public_body_names(request)
    if [InfoRequest, DraftInfoRequest].include?(request.class)
      request.public_body.name unless request.public_body.blank?
    else
      request.public_bodies.pluck(:name).join(" ")
    end
  end

  def self.extract_categories(request)
    categories = []
    if [DraftInfoRequest, AlaveteliPro::DraftInfoRequestBatch].include?(request.class)
      categories << AlaveteliPro::RequestSummaryCategory.draft
    end
    if request.try(:embargo_expiring?)
      categories << AlaveteliPro::RequestSummaryCategory.embargo_expiring
    end
    # A request with no events is in the process of being sent (probably
    # having been created within our tests rather than in real code) and will
    # error if we try to get the phase, skip it for now because it'll be saved
    # when it's sent and trigger this code again anyway.
    # Likewise, a batch request won't have any phases until it's actually sent
    if request.class == InfoRequest && !request.last_event_forming_initial_request_id.nil?
      phase_slug = request.state.phase.to_s
      phase = AlaveteliPro::RequestSummaryCategory.find_by(slug: phase_slug)
      categories << phase unless phase.blank?
    elsif request.class == InfoRequestBatch
      if request.sent_at
        phase_slugs = request.request_phases.map(&:to_s).uniq
        phases = AlaveteliPro::RequestSummaryCategory.where(slug: phase_slugs)
        categories.concat phases
      else
        # A batch info request which hasn't been sent yet won't show up in the
        # list unless we give it some kind of category, so we fake an awaiting
        # response one
        categories << AlaveteliPro::RequestSummaryCategory.awaiting_response
      end
    end
    categories
  end
end

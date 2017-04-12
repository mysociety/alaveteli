# == Schema Information
# Schema version: 20170323165519
#
# Table name: draft_info_request_batches
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  body             :text
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  embargo_duration :string(255)
#

class AlaveteliPro::DraftInfoRequestBatch < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :public_bodies

  validates_presence_of :user

  after_initialize :set_default_body

  def set_default_body
    if body.blank?
      template = OutgoingMessage::Template::BatchRequest.new
      template_options = {}
      template_options[:info_request_title] = title if title
      self.body = template.body(template_options)
      if self.user
        self.body += self.user.name
      end
    end
  end
end

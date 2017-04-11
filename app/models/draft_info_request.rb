# == Schema Information
# Schema version: 20161128095350
#
# Table name: draft_info_requests
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  user_id          :integer
#  public_body_id   :integer
#  body             :text
#  embargo_duration :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class DraftInfoRequest < ActiveRecord::Base
  validates_presence_of :user

  belongs_to :user
  belongs_to :public_body
  has_one :request_summary, :as => :summarisable,
                            :class_name => "AlaveteliPro::RequestSummary",
                            :dependent => :destroy

  strip_attributes
end

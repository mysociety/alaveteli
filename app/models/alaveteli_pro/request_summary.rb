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
end

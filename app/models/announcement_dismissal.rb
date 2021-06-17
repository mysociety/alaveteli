# == Schema Information
# Schema version: 20210114161442
#
# Table name: announcement_dismissals
#
#  id              :integer          not null, primary key
#  announcement_id :integer          not null
#  user_id         :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class AnnouncementDismissal < ApplicationRecord
  belongs_to :announcement,
             inverse_of: :dismissals
  belongs_to :user,
             inverse_of: :announcement_dismissals

  validates :announcement, :user, presence: true
end

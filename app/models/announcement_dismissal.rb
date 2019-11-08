# == Schema Information
# Schema version: 20220322100510
#
# Table name: announcement_dismissals
#
#  id              :bigint           not null, primary key
#  announcement_id :bigint           not null
#  user_id         :bigint           not null
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

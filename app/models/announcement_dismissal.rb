class AnnouncementDismissal < ActiveRecord::Base
  belongs_to :announcement,
             inverse_of: :dismissals
  belongs_to :user,
             inverse_of: :announcement_dismissals

  validates :announcement, :user, presence: true
end

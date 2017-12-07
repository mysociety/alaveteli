class Announcement < ActiveRecord::Base
  has_many :dismissals,
           class_name: 'AnnouncementDismissal',
           inverse_of: :announcement,
           dependent: :destroy

  default_scope -> { order(created_at: :desc) }
  scope :for_user, -> (user) {
    return unless user

    # has the user dismissed the announcement
    where(
      'announcements.id NOT IN (SELECT announcement_id FROM ' \
      'announcement_dismissals WHERE user_id = :user_id)',
      user_id: user
    )
  }

  validates :title, :content, presence: true
end

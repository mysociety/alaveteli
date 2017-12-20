class Announcement < ActiveRecord::Base
  SITE_WIDE = 'everyone'.freeze

  belongs_to :user,
             inverse_of: :announcements
  has_many :dismissals,
           class_name: 'AnnouncementDismissal',
           inverse_of: :announcement,
           dependent: :destroy

  translates :title, :content
  include Translatable

  default_scope -> { order(created_at: :desc) }
  scope :site_wide, -> { visible_to(SITE_WIDE) }
  scope :visible_to, -> (visible_to) { where(visibility: visible_to) }

  scope :for_user, -> (user) {
    return unless user

    # has the user dismissed the announcement
    where(
      'announcements.id NOT IN (SELECT announcement_id FROM ' \
      'announcement_dismissals WHERE user_id = :user_id)',
      user_id: user
    ).

    # does the announcement have the same visibility role as the user or set
    # to be visible to everyone
    where(
      'announcements.visibility = :site_wide OR ' \
      'announcements.visibility IN (' \
        'SELECT roles.name FROM roles ' \
        'INNER JOIN users_roles ON users_roles.role_id = roles.id ' \
        'WHERE users_roles.user_id = :user_id' \
      ')',
      site_wide: SITE_WIDE,
      user_id: user
    )
  }

  scope :for_user_with_roles, -> (user, *roles) {
    for_user(user).visible_to(roles)
  }

  validates :content, :user,
            presence: true
  validates :visibility,
            presence: true,
            inclusion: { in: [SITE_WIDE] + Role.allowed_roles }

  after_initialize :set_defaults

  private

  def set_defaults
    self.visibility ||= SITE_WIDE
  end
end

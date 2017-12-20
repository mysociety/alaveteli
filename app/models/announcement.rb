class Announcement < ActiveRecord::Base
  belongs_to :user,
             inverse_of: :announcements
  has_many :dismissals,
           class_name: 'AnnouncementDismissal',
           inverse_of: :announcement,
           dependent: :destroy

  translates :title, :content
  include Translatable

  default_scope -> { order(created_at: :desc) }
  scope :for_user, -> (user) {
    return unless user

    # has the user dismissed the announcement
    where(
      'announcements.id NOT IN (SELECT announcement_id FROM ' \
      'announcement_dismissals WHERE user_id = :user_id)',
      user_id: user
    ).
    # does the announcement have the same visibility role as the user or set to
    # be visible to everyone
    where(
      'announcements.visibility = \'everyone\' OR ' \
      'announcements.visibility IN (' \
        'SELECT roles.name FROM roles ' \
        'INNER JOIN users_roles ON users_roles.role_id = roles.id ' \
        'WHERE users_roles.user_id = :user_id' \
      ')',
      user_id: user
    )
  }

  validates :content, :user,
            presence: true
  validates :visibility,
            presence: true,
            inclusion: { in: ['everyone'] + Role.allowed_roles }

  after_initialize :set_defaults

  private

  def set_defaults
    self.visibility ||= 'everyone'
  end
end

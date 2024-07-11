module Comment::Erasable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :old_age_in_days,
                   instance_reader: false,
                   instance_writer: false,
                   instance_accessor: false,
                   default: 30
  end

  class_methods do
    def erase_old_hidden(editor: User.internal_admin_user)
      old_hidden = hidden.where('updated_at > ?', old_age_in_days.days.ago)
      reason = "Hidden for longer than #{old_age_in_days} days"

      old_hidden.find_each do |comment|
        comment.erase(editor: editor, reason: reason)
      end
    end
  end

  def erase(**kwargs)
    return false unless hidden?
    Comment::Erasure.new(self, **kwargs).erase
  end

  def erased?
    info_request_events.erase_comment_events.any?
  end
end

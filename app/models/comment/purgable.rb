module Comment::Purgable
  extend ActiveSupport::Concern

  included do
    cattr_accessor :old_age_in_days,
                   instance_reader: false,
                   instance_writer: false,
                   instance_accessor: false,
                   default: 30
  end

  class_methods do
    def purge_old_hidden(editor: User.internal_admin_user)
      old_hidden = hidden.where('updated_at > ?', old_age_in_days.days.ago)
      reason = "Hidden for longer than #{old_age_in_days} days"

      old_hidden.find_each do |comment|
        comment.purge(editor: editor, reason: reason)
      end
    end
  end

  def purge(editor:, reason:)
    return false unless hidden?

    event_params = {
      comment_id: id,
      comment_created_at: created_at,
      comment_user: user,
      editor: editor.url_name,
      reason: "Purged: #{reason}"
    }

    ActiveRecord::Base.transaction do
      destroy!
      info_request_events.create!('destroy_comment', event_params)
    end
  end
end

class Comment::Erasure
  def initialize(comment, editor: User.internal_admin_user, reason:)
    @comment = comment
    @editor = editor
    @reason = reason
  end

  def erase
    ActiveRecord::Base.transaction do
      erase_comment
      erase_comment_events
    end
  end

  protected

  attr_reader :comment, :editor, :reason

  private

  def erase_comment
    event_params = {
      comment_id: comment.id,
      editor: editor.url_name,
      reason: "Erased: #{reason}"
    }

    comment.update!(body: '')
    comment.info_request.log_event('erase_comment', event_params)
  end

  def erase_comment_events
    comment.info_request_events.edit_comment_events.find_each do |event|
      params = event.params.dup

      params.each do |key, _|
        params[key] = "[ERASED]" if key =~ /body/
      end

      event.update(params: params)
    end
  end
end

module NotesHelper
  def render_notes(notes, batch: false, **options)
    return unless notes.present?

    allowed_tags = batch ? batch_notes_allowed_tags : notes_allowed_tags

    tag.aside(**options.merge(id: 'notes')) do
      notes.each do |note|
        concat render_note(note, allowed_tags: allowed_tags)
      end
    end
  end

  def notes_allowed_tags
    Alaveteli::Application.config.action_view.sanitized_allowed_tags +
      %w(th time u font iframe) -
      %w(html head body style)
  end

  def batch_notes_allowed_tags
    notes_allowed_tags - %w(pre h1 h2 h3 h4 h5 h6 img blockquote font iframe)
  end

  private

  def render_note(note, allowed_tags: notes_allowed_tags)
    note_classes = ['note']
    note_classes << "tag-#{note.notable_tag}" if note.notable_tag

    locals = {
      note_classes: note_classes,
      allowed_tags: allowed_tags
    }

    render partial: note, locals: locals
  end
end

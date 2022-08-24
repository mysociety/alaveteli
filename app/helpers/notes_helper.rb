module NotesHelper
  def render_notes(notes, batch: false, **options)
    @notes_allowed_tags = batch ? batch_notes_allowed_tags : notes_allowed_tags

    tag.aside options.merge(id: 'notes') do
      render partial: 'notes/note',
             collection: notes,
             locals: {
               note_class: ['note'],
               batch: batch
             }
    end
  end

  def sanitized_note(note)
    sanitize(note.body, tags: @notes_allowed_tags)
  end

  def notes_allowed_tags
    Alaveteli::Application.config.action_view.sanitized_allowed_tags +
      %w(th time u font iframe) -
      %w(html head body style)
  end

  def batch_notes_allowed_tags
    notes_allowed_tags - %w(pre h1 h2 h3 h4 h5 h6 img blockquote font iframe)
  end

  def note_class(note)
    klasses = ['note']
    klasses << "tag-#{note.notable_tag}" if note.notable_tag
    klasses
  end
end

module NotesHelper
  def render_notes(notes, batch: false, **options)
    allowed_tags = batch ? batch_notes_allowed_tags : notes_allowed_tags

    tag.aside options.merge(id: 'notes') do
      notes.each do |note|
        note_classes = ['note']
        note_classes << "tag-#{note.notable_tag}" if note.notable_tag

        concat tag.article sanitize(note.body, tags: allowed_tags),
                           id: dom_id(note),
                           class: note_classes
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
end

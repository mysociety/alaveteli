module NotesHelper
  def render_notes(notes, batch: false, **options)
    allowed_tags = batch ? batch_notes_allowed_tags : notes_allowed_tags

    tag.p options do
      sanitize(notes, tags: allowed_tags)
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

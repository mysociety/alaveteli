# Helpers for displaying Citations in the admin interface
module Admin::CitationsHelper
  ICONS = {
    journalism: '🗞️',
    academic: '🎓',
    other: '🌐'
  }.with_indifferent_access.freeze

  def citation_icon(citation)
    html_attrs = {
      title: citation.type.humanize,
      class: "citation-icon citation-icon--#{citation.type}"
    }

    tag.span(ICONS.fetch(citation.type), **html_attrs)
  end
end

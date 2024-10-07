# Helpers for displaying Citations in the admin interface
module Admin::CitationsHelper
  ICONS = {
    journalism: '🗞️',
    campaigning: '📣',
    research: '📚',
    other: '🌐'
  }.with_indifferent_access.freeze

  def citation_title(citation)
    citation.title.presence || citation.source_url
  end

  def citation_icon(citation)
    citation_icon_for_type(citation.type)
  end

  def citation_icon_for_type(type)
    html_attrs = {
      title: type.humanize,
      class: "citation-icon citation-icon--#{type}"
    }

    tag.span(ICONS.fetch(type), **html_attrs)
  end
end

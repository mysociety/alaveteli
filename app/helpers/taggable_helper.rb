# Helpers for Taggable records
module TaggableHelper
  # Generate CSS classes for each tag of a given Taggable
  def tags_css(taggable)
    taggable.tags.map { |tag| "tag--#{tag.name}" }.join(' ')
  end
end

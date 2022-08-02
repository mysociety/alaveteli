# Helpers for rendering HasTagStringTags
module Admin::TagHelper
  def render_tags(tags)
    tags.
      map { |record_tag| render_tag(record_tag) }.
      join.
      html_safe
  end

  def render_tag(record_tag)
    tag.span class: 'label label-info tag' do
      render_tag_href(record_tag)
    end
  end

  private

  def render_tag_href(record_tag)
    str = link_to h(record_tag.name), "##{record_tag.name}"

    if record_tag.value
      path = "##{record_tag.name_and_value}"
      str += ':'
      str += link_to h(record_tag.value), path
    end

    str
  end
end

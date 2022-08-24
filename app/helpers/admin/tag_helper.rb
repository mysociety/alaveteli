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
      if record_tag.is_a?(String)
        record_tag = HasTagString::HasTagStringTag.from_string(record_tag)
      end

      render_tag_href(record_tag)
    end
  end

  private

  def render_tag_href(record_tag)
    path = admin_tag_path(record_tag.name, model_type: record_tag.model_type)

    str = link_to h(record_tag.name), path

    if record_tag.value
      path = admin_tag_path(
        record_tag.name_and_value, model_type: record_tag.model_type
      )
      str += ':'
      str += link_to h(record_tag.value), path
    end

    str
  end
end

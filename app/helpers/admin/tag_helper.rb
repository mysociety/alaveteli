# Helpers for rendering HasTagStringTags
module Admin::TagHelper
  def render_tags(tags, search_target: nil)
    tags.
      map { |record_tag| render_tag(record_tag, search_target: search_target) }.
      join.
      html_safe
  end

  def render_tag(record_tag, search_target: nil)
    tag.span class: 'label label-info tag' do
      if search_target
        render_tag_href(record_tag, search_target)
      else
        render_tag_plain(record_tag)
      end
    end
  end

  private

  def render_tag_plain(record_tag)
    str = record_tag.name
    str += ":#{record_tag.value}" if record_tag.value
    str
  end

  def render_tag_href(record_tag, search_target)
    str = link_to h(record_tag.name),
                    search_target_and_query(search_target, record_tag.name)

    if record_tag.value
      path = search_target_and_query(search_target, record_tag.name_and_value)
      str += ':'
      str += link_to h(record_tag.value), path
    end

    str
  end

  def search_target_and_query(search_target, query)
    query = URI::Generic.build(query: "tag=#{CGI.escape(query)}").to_s
    search_target + query
  end
end

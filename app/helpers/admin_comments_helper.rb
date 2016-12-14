# -*- encoding : utf-8 -*-

module AdminCommentsHelper
  def comment_labels(comment)
    html = ''
    html += hidden_label if comment.hidden?
    html.html_safe
  end

  private

  def hidden_label
    content_tag(:span, 'hidden', :class => 'label label-warning')
  end
end

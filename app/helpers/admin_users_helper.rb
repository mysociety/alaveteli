# -*- encoding : utf-8 -*-
module AdminUsersHelper
  def user_labels(user)
    html = ''
    html += banned_label if user.banned?
    html += superuser_label if user.is_admin?
    html.html_safe
  end

  private

  def banned_label
    content_tag(:span, 'banned', :class => 'label label-warning')
  end

  def superuser_label
    content_tag(:span, 'superuser', :class => 'label')
  end
end

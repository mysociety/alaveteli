# -*- encoding : utf-8 -*-
module AdminUsersHelper
  def user_labels(user)
    html = ''
    html += banned_label if user.banned?
    user.roles.each do |role|
      html += role_label(role)
    end
    html.html_safe
  end

  private

  def banned_label
    content_tag(:span, 'banned', :class => 'label label-warning')
  end

  def role_label(role)
    content_tag(:span, role.name, :class => 'label')
  end

end

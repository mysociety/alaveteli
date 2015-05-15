# -*- encoding : utf-8 -*-
module AdminHelper
  def icon(name)
    content_tag(:i, "", :class => "icon-#{name}")
  end

  def eye
    icon("eye-open")
  end

  def chevron_right
    icon("chevron-right")
  end

  def chevron_down
    icon("chevron-down")
  end

  def arrow_right
    icon("arrow-right")
  end

  def request_both_links(info_request)
      link_to(eye, request_path(info_request), :title => "view request on public website") + " " +
          link_to(info_request.title, admin_request_path(info_request), :title => "view full details")
  end

  def public_body_both_links(public_body)
      link_to(eye, public_body_path(public_body), :title => "view authority on public website") + " " +
          link_to(h(public_body.name), admin_body_path(public_body), :title => "view full details")
  end

  def user_both_links(user)
      link_to(eye, user_path(user), :title => "view user's page on public website") + " " +
        link_to(h(user.name), admin_user_path(user), :title => "view full details")
  end

  def comment_visibility(comment)
      comment.visible? ? 'Visible' : 'Hidden'
  end

end


module AdminHelper
  def icon(name)
    content_tag(:i, "", :class => "icon-#{name}")
  end

  def eye_icon
    icon("eye-open")
  end

  def request_both_links(info_request)
      link_to(eye_icon, request_path(info_request)) + " " +
          link_to(info_request.title, admin_request_show_url(info_request))
  end

  def public_body_both_links(public_body)
      link_to(eye_icon, public_body_url(public_body)) + " " +
          link_to(h(public_body.name), admin_body_show_path(public_body))
  end

  def user_both_links(user)
      link_to(h(user.name), user_url(user)) + " (" + link_to("admin", admin_user_show_url(user)) + ")"
  end

  def request_admin_link(info_request, name="admin", cls=nil)
    link_to name, admin_request_show_url(info_request), :class => cls
  end
end


# Helpers for rendering record links in the admin interface
module Admin::LinkHelper
  def both_links(record)
    method = "#{record.class.to_s.underscore}_both_links"
    send(method, record)
  end

  private

  def info_request_both_links(info_request)
    link_to(prominence_icon(info_request), request_path(info_request), title: 'View request on public website') + ' ' +
      link_to(info_request.title, admin_request_path(info_request), title: 'View full details')
  end

  def public_body_both_links(public_body)
    link_to(eye, public_body_path(public_body), title: 'View authority on public website') + ' ' +
      link_to(h(public_body.name), admin_body_path(public_body), title: 'View full details')
  end

  def user_both_links(user)
    link_to(prominence_icon(user.prominence), user_path(user), title: 'View user on public website') + ' ' +
      link_to(h(user.name), admin_user_path(user), title: 'View full details')
  end

  def comment_both_links(comment)
    link_to(prominence_icon(comment), comment_path(comment),
            title: 'View comment on public website') + ' ' +
      link_to(h(truncate(comment.body)), edit_admin_comment_path(comment),
              title: 'View full details')
  end
end

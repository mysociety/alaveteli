# Helpers for rendering record links in the admin interface
module Admin::LinkHelper
  def both_links(record)
    method = "#{record.class.to_s.underscore}_both_links"
    send(method, record)
  end

  private

  def info_request_both_links(info_request)
    title = 'View request on public website'
    icon = prominence_icon(info_request)

    link_to(icon, request_path(info_request), title: title) + ' ' +
      link_to(info_request.title, admin_request_path(info_request),
              title: admin_title)
  end

  def info_request_batch_both_links(batch)
    title = 'View batch on public website'
    icon = prominence_icon(batch)

    link_to(icon, batch, title: title) + ' ' + batch.title
  end

  def public_body_both_links(public_body)
    title = 'View authority on public website'
    icon = eye

    link_to(icon, public_body_path(public_body), title: title) + ' ' +
      link_to(h(public_body.name), admin_body_path(public_body),
              title: admin_title)
  end

  def user_both_links(user)
    title = 'View user on public website'
    icon = prominence_icon(user.prominence)

    link_to(icon, user_path(user), title: title) + ' ' +
      link_to(h(user.name), admin_user_path(user), title: admin_title)
  end

  def comment_both_links(comment)
    title = 'View comment on public website'
    icon = prominence_icon(comment)

    link_to(icon, comment_path(comment), title: title) + ' ' +
      link_to(h(truncate(comment.body)), edit_admin_comment_path(comment),
              title: admin_title)
  end

  def admin_title
    'View full details'
  end
end

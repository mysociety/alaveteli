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

  def outgoing_message_both_links(outgoing_message)
    title = 'View outgoing message on public website'
    icon = prominence_icon(outgoing_message)
    info_request = outgoing_message.info_request

    link_to(icon, outgoing_message_path(outgoing_message), title: title) + ' ' +
      link_to("#{info_request.title} #outgoing-#{outgoing_message.id}",
              edit_admin_outgoing_message_path(outgoing_message),
              title: admin_title)
  end

  def incoming_message_both_links(incoming_message)
    title = 'View incoming message on public website'
    icon = prominence_icon(incoming_message)
    info_request = incoming_message.info_request

    link_to(icon, incoming_message_path(incoming_message), title: title) + ' ' +
      link_to("#{info_request.title} #incoming-#{incoming_message.id}",
              edit_admin_incoming_message_path(incoming_message),
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
      link_to(public_body.name, admin_body_path(public_body),
              title: admin_title)
  end

  def user_both_links(user)
    title = 'View user on public website'
    icon = prominence_icon(user)

    link_to(icon, user_path(user), title: title) + ' ' +
      link_to(user.name, admin_user_path(user), title: admin_title)
  end

  def comment_both_links(comment)
    title = 'View comment on public website'
    icon = prominence_icon(comment)

    link_to(icon, comment_path(comment), title: title) + ' ' +
      link_to(truncate(comment.body), edit_admin_comment_path(comment),
              title: admin_title)
  end

  def admin_title
    'View full details'
  end
end

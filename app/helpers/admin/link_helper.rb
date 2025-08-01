# Helpers for rendering record links in the admin interface
module Admin::LinkHelper
  def both_links(record)
    type = record.class.to_s.underscore.parameterize(separator: '_')
    send("#{type}_both_links", record)
  end

  private

  def info_request_both_links(info_request)
    title = 'View request on public website'
    icon = prominence_icon(info_request)

    link_to(icon, request_path(info_request), title: title) + ' ' +
      classification_icon(info_request) + ' ' +
        link_to(info_request.title, admin_request_path(info_request),
                title: admin_title)
  end

  def outgoing_message_both_links(outgoing_message)
    title = 'View outgoing message on public website'
    icon = prominence_icon(outgoing_message)
    info_request = outgoing_message.info_request

    link_to(icon, outgoing_message_path(outgoing_message), title: title) + ' ' +
      link_to("#{info_request.title} ##{dom_id(outgoing_message)}",
              edit_admin_outgoing_message_path(outgoing_message),
              title: admin_title)
  end

  def incoming_message_both_links(incoming_message)
    title = 'View incoming message on public website'
    icon = prominence_icon(incoming_message)
    info_request = incoming_message.info_request

    link_to(icon, incoming_message_path(incoming_message), title: title) + ' ' +
      link_to("#{info_request.title} ##{dom_id(incoming_message)}",
              edit_admin_incoming_message_path(incoming_message),
              title: admin_title)
  end

  def foi_attachment_both_links(foi_attachment)
    title = 'View attachment on public website'
    icon = prominence_icon(foi_attachment)
    info_request = foi_attachment.incoming_message.info_request

    link_to(icon, foi_attachment_path(foi_attachment), title: title) + ' ' +
      link_to(foi_attachment.filename,
              edit_admin_foi_attachment_path(foi_attachment),
              title: admin_title)
  end

  def info_request_batch_both_links(batch)
    title = 'View batch on public website'
    icon = prominence_icon(batch)

    link_to(icon, batch, title: title) + ' ' +
      link_to(batch.title,
              admin_info_request_batch_path(batch),
              title: admin_title)
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
      link_to(truncate(comment.body, length: 60), edit_admin_comment_path(comment),
              title: admin_title)
  end

  def blog_post_both_links(blog_post)
    title = 'View blog post'
    icon = eye

    link_to(icon, blog_post.url, title: title) + ' ' +
      link_to(blog_post.title, edit_admin_blog_post_path(blog_post),
              title: admin_title)
  end

  def track_thing_both_links(track_thing)
    title = 'View track'
    icon = eye
    icon_link = search_general_path(track_thing.track_query)

    link_to(icon, icon_link, title: title) + ' ' + "#{track_thing.id}:"
  end

  def category_both_links(category)
    # No public links, yet?
    link_to(category.title, edit_admin_category_path(category),
            title: admin_title)
  end

  def citation_both_links(citation)
    title = 'View citation'
    icon = eye

    link_to(icon, citation.source_url, title: title) + ' ' +
      link_to(citation.source_url, edit_admin_citation_path(citation),
              title: admin_title)
  end

  def admin_title
    'View full details'
  end
end

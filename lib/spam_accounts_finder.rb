# -*- encoding : utf-8 -*-
module SpamAccountsFinder

  URL_MATCH = /https?:\/\/[^\s]+/

  def potential_spammers(max=100)
    User.includes(:info_requests).
      where(
        "info_requests.user_id IS NULL AND
         about_me LIKE '%http%' AND
         ban_text = ''").
      order("users.created_at DESC").
      limit(max)
  end

  def display_detail(account, show_full=false)
    p "Created: #{account.created_at}"
    p "Name: #{account.name}"
    p "Email: #{account.email}"
    p "Link(s): #{extract_links(account.about_me).join(", ")}"
    p "Profile: #{account.about_me}" if show_full
    ""
  end

  def extract_links(text)
    text.scan(URL_MATCH)
  end

  def ban!(account)
    account.ban_text = "Banned for spamming"
    account.save!
  end

end

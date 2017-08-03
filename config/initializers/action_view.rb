# -*- encoding : utf-8 -*-
Rails.application.configure do
  rails_41_default_tags = %w(strong em b i p code pre tt samp kbd var sub
                             sup dfn cite big small address hr br div span h1
                             h2 h3 h4 h5 h6 ul ol li dl dt dd abbr acronym a
                             img blockquote del ins)
  alaveteli_extra_tags = %w(html head body table tr td style)

  allowed_tags = rails_41_default_tags + alaveteli_extra_tags

  # Allow some extra tags to be whitelisted in the 'sanitize' helper method
  config.action_view.sanitized_allowed_tags = allowed_tags
end

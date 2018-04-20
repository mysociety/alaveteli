# -*- encoding : utf-8 -*-
module AlaveteliPro
  # Helper methods for the batch builder
  module BatchRequestAuthoritySearchesHelper
    def batch_notes_allowed_tags
      Alaveteli::Application.config.action_view.sanitized_allowed_tags -
        %w(pre h1 h2 h3 h4 h5 h6 img blockquote html head body style)
    end
  end
end

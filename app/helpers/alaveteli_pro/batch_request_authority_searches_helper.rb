module AlaveteliPro
  # Helper methods for the batch builder
  module BatchRequestAuthoritySearchesHelper
    def batch_notes_allowed_tags
      Alaveteli::Application.config.action_view.sanitized_allowed_tags -
        %w(pre h1 h2 h3 h4 h5 h6 img blockquote html head body style)
    end

    def batch_authority_count
      count = @draft_batch_request.public_bodies.count

      tag_attributes = {
        class: %w[batch-builder__actions__count],
        data: {
          message_template_zero: authority_count(count_override: 0),
          message_template_one:  authority_count(count_override: 1),
          message_template_many: authority_count(count_override: 2)
        }
      }

      content_tag :p, authority_count, tag_attributes
    end

    private

    def authority_count(count_override: nil)
      limit = AlaveteliConfiguration.pro_batch_authority_limit

      count = count_override || @draft_batch_request.public_bodies.count
      count_text = '{{count}}' if count_override
      count_text ||= count

      n_("{{count}} of {{limit}} authorities",
         "{{count}} of {{limit}} authorities",
         count, count: count_text, limit: limit)
    end
  end
end

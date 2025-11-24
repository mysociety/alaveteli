module AlaveteliPro
  # Helper methods for the batch builder
  module BatchRequestAuthoritySearchesHelper
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

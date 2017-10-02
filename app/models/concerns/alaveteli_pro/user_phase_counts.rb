# -*- encoding : utf-8 -*-
module AlaveteliPro
  module UserPhaseCounts

    extend ActiveSupport::Concern

    def phase_count(key)
      key = key.to_s
      if raw_counts.keys.include?(key)
        raw_counts[key]
      else
        0
      end
    end

    private

    def raw_counts
      @raw_counts =
        request_summaries.
          joins(:request_summary_categories).
          references(:request_summary_categories).
          group("request_summary_categories.slug").
          count("request_summary_categories.id")
      @raw_counts['not_drafts'] = request_summaries.not_category(:draft).count
      @raw_counts
    end
  end
end

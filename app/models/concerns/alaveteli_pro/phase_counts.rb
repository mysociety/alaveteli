# -*- encoding : utf-8 -*-
module AlaveteliPro
  module PhaseCounts
    extend ActiveSupport::Concern

    def phase_counts
      @phase_counts ||= phase_counts!
    end

    def phase_counts!
      # Create a Hash that has a default value of 0 for new/unset keys
      hash_with_default = Hash.new(0)

      # Calculate the phase totals from the request_summary_categories
      raw_counts =
        request_summaries.
          joins(:request_summary_categories).
          references(:request_summary_categories).
          group("request_summary_categories.slug").
          count("request_summary_categories.id")
      raw_counts['not_drafts'] = request_summaries.not_category(:draft).count

      @phase_counts =
        hash_with_default.merge(raw_counts).with_indifferent_access
    end
  end
end

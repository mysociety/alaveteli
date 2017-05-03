# -*- encoding : utf-8 -*-
module AlaveteliPro
  module RequestSummaries

    extend ActiveSupport::Concern

    included do
      has_one :request_summary, :as => :summarisable,
                                :class_name => "AlaveteliPro::RequestSummary",
                                :dependent => :destroy
      after_save :create_or_update_request_summary
    end

    # Creates a RequestSummary item for this model on first save, or updates
    # the existing one otherwise.
    def create_or_update_request_summary
      if self.should_summarise?
        self.request_summary = AlaveteliPro::RequestSummary.create_or_update_from(self)
      end
    end

    # Should a particular instance of a model have a request summary made of
    # it? Override this if you want to have more fine-grained control over
    # which records get RequestSummaries made for them
    def should_summarise?
      true
    end
  end
end

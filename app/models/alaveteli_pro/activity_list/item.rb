# -*- encoding : utf-8 -*-
module AlaveteliPro
  module ActivityList
    class Item

      include Rails.application.routes.url_helpers
      include LinkToHelper
      include ActionView::Helpers::DateHelper

      attr_accessor :event, :info_request, :public_body

      def initialize(event)
        @event = event
        @info_request = @event.info_request
        @public_body = @info_request.public_body
      end

      def info_request_path
        request_path(info_request)
      end

      def info_request_title
        info_request.title
      end

      def body_name
        public_body.name
      end

      def body_path
        public_body_path(public_body)
      end

      def call_to_action
        _("View")
      end

      def description_urls
        { :public_body_name => { :text => body_name, :url => body_path },
          :info_request_title => { :text => info_request_title, :url => info_request_path } }
      end

      def event_time
        event.created_at
      end

    end
  end
end

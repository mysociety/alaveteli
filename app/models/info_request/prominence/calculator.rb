# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class Calculator

      def initialize(info_request)
        @info_request = info_request
      end

      # Is this request visible to everyone?
      def is_public?
        %w(normal backpage).include?(to_s)
      end

      # Is this request findable via search?
      def is_searchable?
        to_s == 'normal'
      end

      # Is this request hidden from some people?
      def is_private?
        %w(hidden requester_only).include?(to_s)
      end

      # Is this request visible only to admins and the requester?
      def is_requester_only?
        to_s == 'requester_only'
      end

      # Is this request visible only to admins?
      def is_hidden?
        to_s == 'hidden'
      end

      def to_s
        @info_request.read_attribute(:prominence)
      end

    end
  end
end

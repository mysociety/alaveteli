# -*- encoding : utf-8 -*-
class InfoRequest
  module State
    module Transitions
      def self.transition_label(to_state, opts = {})
        is_owning_user = opts.fetch(:is_owning_user)
        user = is_owning_user ? "owner" : "other_user"
        method = "#{user}_#{to_state}_transition_label"
        if respond_to?(method, true)
          send(method, opts)
        else
          raise "No transition_label for #{to_state}. Should an #{user} " \
                "be transitioning to this state? (looking for method " \
                "named #{method})"
        end
      end

      def self.labelled_hash(states, opts = {})
        hash = {}
        states.each do |state|
          hash[state] = self.transition_label(state, opts)
        end
        hash
      end

      private

      def self.owner_waiting_response_transition_label(opts = {})
        _("I'm still <strong>waiting</strong> for my information <small>(maybe you got an acknowledgement)</small>")
      end

      def self.owner_not_held_transition_label(opts = {})
        _("They do <strong>not have</strong> the information <small>(maybe they say who does)</small>")
      end

      def self.owner_rejected_transition_label(opts = {})
        _("My request has been <strong>refused</strong>")
      end

      def self.owner_partially_successful_transition_label(opts = {})
        _("I've received <strong>some of the information</strong>")
      end

      def self.owner_successful_transition_label(opts = {})
        _("I've received <strong>all the information")
      end

      def self.owner_waiting_clarification_transition_label(opts = {})
        _("I've been asked to <strong>clarify</strong> my request")
      end

      def self.owner_gone_postal_transition_label(opts = {})
        _("They are going to reply <strong>by post</strong>")
      end

      def self.owner_internal_review_transition_label(opts = {})
        if opts.fetch(:in_internal_review, false)
          _("I'm still <strong>waiting</strong> for the internal review")
        else
          _("I'm waiting for an <strong>internal review</strong> response")
        end
      end

      def self.owner_error_message_transition_label(opts = {})
        _("I've received an <strong>error message</strong>")
      end

      def self.owner_requires_admin_transition_label(opts = {})
        _("This request <strong>requires administrator attention</strong>")
      end

      def self.owner_user_withdrawn_transition_label(opts = {})
        _("I would like to <strong>withdraw this request</strong>")
      end

      def self.other_user_waiting_response_transition_label(opts = {})
        _("<strong>No response</strong> has been received <small>(maybe " \
          "there's just an acknowledgement)</small>")
      end

      def self.other_user_not_held_transition_label(opts = {})
        _("The authority do <strong>not have</strong> the information " \
          "<small>(maybe they say who does)</small>")
      end

      def self.other_user_rejected_transition_label(opts = {})
        _("The request has been <strong>refused</strong>")
      end

      def self.other_user_partially_successful_transition_label(opts = {})
        # TODO - trailing space copied from
        # views/request/_other_describe_state.html.erb, will it break
        # translations if I fix it?
        _("<strong>Some of the information</strong> has been sent ")
      end

      def self.other_user_successful_transition_label(opts = {})
        _("<strong>All the information</strong> has been sent")
      end

      def self.other_user_waiting_clarification_transition_label(opts = {})
        _("<strong>Clarification</strong> has been requested")
      end

      def self.other_user_gone_postal_transition_label(opts = {})
        _("A response will be sent <strong>by post</strong>")
      end

      def self.other_user_internal_review_transition_label(opts = {})
        if opts.fetch(:in_internal_review, false)
          _("Still awaiting an <strong>internal review</strong>")
        else
          # To match what would happen if this method didn't exist, because
          # it shouldn't for this situation
          raise "Only the request owner can request an internal_review."
        end
      end

      def self.other_user_error_message_transition_label(opts = {})
        _("An <strong>error message</strong> has been received")
      end
    end
  end
end

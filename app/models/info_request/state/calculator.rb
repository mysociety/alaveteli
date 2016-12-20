# -*- encoding : utf-8 -*-
class InfoRequest
  module State
    class Calculator

      def initialize(info_request)
        @info_request = info_request
      end

      def phase(cached_value_ok=false)
        if @info_request.awaiting_description?
          :response_received
        else
          state = @info_request.calculate_status(cached_value_ok)
          case state
            when 'not_held',
                 'rejected',
                 'successful',
                 'partially_successful',
                 'user_withdrawn'
              :complete
            when 'waiting_clarification'
              :clarification_needed
            when 'waiting_response'
              :awaiting_response
            when 'gone_postal',
                 'internal_review',
                 'error_message',
                 'requires_admin',
                 'attention_requested',
                 'vexatious',
                 'not_foi'
              :other
          end
        end
      end

      def transitions(opts = {})
        cached_value_ok = opts.fetch(:cached_value_ok, false)
        state = @info_request.calculate_status(cached_value_ok)
        if complete_states(include_admin_states: true).include?(state)
          return {
            pending: {},
            complete: {},
            other: {}
          }
        end
        opts.merge!(in_internal_review: state == 'internal_review')
        build_transitions_hash(opts)
      end

      private

      def build_transitions_hash(opts)
        hash = {}
        [:pending, :complete, :other].each do |group|
          method = "#{group}_states"
          states = send(method, opts)
          hash[group] = Transitions.labelled_hash(states, opts)
        end
        hash
      end

      def pending_states(opts)
        # Which pending states can we transition into
        if opts.fetch(:in_internal_review, false)
          states = ['internal_review', 'gone_postal']
        else
          states = [
            'waiting_response',
            'waiting_clarification',
            'gone_postal'
          ]
          if opts.fetch(:user_asked_to_update_status, false)
            states += ['internal_review']
          end
        end
        states
      end

      def complete_states(opts = {})
        # States from which a request can go no further, because it's complete
        states = [
          'not_held',
          'partially_successful',
          'successful',
          'rejected'
        ]
        if opts.fetch(:include_admin_states, false)
          states += ['not_foi', 'vexatious']
        end
        states
      end

      def other_states(opts = {})
        is_owning_user = opts.fetch(:is_owning_user, false)
        user_asked_to_update_status = opts.fetch(:user_asked_to_update_status, false)
        states = ['error_message']
        if user_asked_to_update_status && is_owning_user
          states += ['requires_admin', 'user_withdrawn']
        end
        states
      end
    end
  end
end

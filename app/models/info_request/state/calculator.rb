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
            when 'waiting_response_overdue'
              :overdue
            when 'waiting_response_very_overdue'
              :very_overdue
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

      # Calculates the available state transitions for the current request
      # and returns a hash of hashes, containing groups of states and their
      # accompanying labels, for presenting options to a user when updating
      # the request's status.
      #
      # @see InfoRequest::State::Transitions for the full list of labels
      # @see InfoRequest::State::Transitions.transition_label for options
      #   which can be passed through to control which labels are returned.
      #
      # @param [Hash] opts options to control the transition labels that are
      #   returned. Options will also be passed through to
      #    InfoRequest::State::Transitions#transition_label, so see
      #    documentation there for a full list.
      # @option opts [Boolean] :cached_value_ok is it ok to use a cached value
      #   for the request's current status? (optional, defaults to false)
      # @option opts [Boolean] :user_asked_to_update_status has the user
      #   explicitly asked to update the request status, or is the form just
      #   being shown incidentally? If true, more status options will be given
      #   (optional, defaults to false)
      #
      # @example transitions for a user
      #   calculator.transitions(is_owning_user: true,
      #                          user_asked_to_update_status: true)
      #   #=> {
      #     pending:  {
      #       "waiting_response"      => "I'm still <strong>waiting</strong> for my information <small>(maybe you got an acknowledgement)</small>",
      #       "waiting_clarification" => "I've been asked to <strong>clarify</strong> my request",
      #       "internal_review"       => "I'm waiting for an <strong>internal review</strong> response",
      #       "gone_postal"           => "They are going to reply <strong>by postal mail</strong>"
      #     },
      #     complete: {
      #       "not_held"              => "They do <strong>not have</strong> the information <small>(maybe they say who does)</small>",
      #       "partially_successful"  => "I've received <strong>some of the information</strong>",
      #       "successful"            => "I've received <strong>all the information</strong>",
      #       "rejected"              => "My request has been <strong>refused</strong>"
      #     },
      #     other: {
      #       "error_message"         => "I've received an <strong>error message</strong>",
      #       "requires_admin"        => "This request <strong>requires administrator attention</strong>",
      #       "user_withdrawn"        => "I would like to <strong>withdraw this request</strong>"
      #     }
      #   }
      #
      # @return [Hash] a hash with three keys, :pending, :complete, and :other
      #   which themselves contain hashes of the form state => label.
      def transitions(opts = {})
        cached_value_ok = opts.fetch(:cached_value_ok, false)
        state = @info_request.calculate_status(cached_value_ok)
        if admin_states.include?(state)
          return {
            pending: {},
            complete: {},
            other: {}
          }
        end
        opts.merge!(in_internal_review: state == 'internal_review')
        build_transitions_hash(opts)
      end

      # A summarised version of #phase, grouping the phases down into 3 groups
      def summarised_phase(cached_value_ok=false)
        phase = phase(cached_value_ok)
        case phase
          when :awaiting_response
            :in_progress
          when :complete
            :complete
          when :other
            :other
          when :response_received,
               :clarification_needed,
               :overdue,
               :very_overdue
            :action_needed
        end
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
        [
          'not_held',
          'partially_successful',
          'successful',
          'rejected'
        ]
      end

      def admin_states(opts = {})
        # States which only an admin can put a request into, and from which
        # a normal user can't get the request out again
        ['not_foi', 'vexatious']
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

# -*- encoding : utf-8 -*-
class InfoRequest
  module State

    def self.all
      states = [
        'waiting_response',
        'waiting_clarification',
        'gone_postal',
        'not_held',
        'rejected', # this is called 'refused' in UK FOI law and the user interface, but 'rejected' internally for historic reasons
        'successful',
        'partially_successful',
        'internal_review',
        'error_message',
        'requires_admin',
        'user_withdrawn',
        'attention_requested',
        'vexatious',
        'not_foi'
      ]
      if InfoRequest.custom_states_loaded
        states += InfoRequest.theme_extra_states
      end
      states
    end

    def self.phases
      [ { name: _('Awaiting response'),
          scope: :awaiting_response },
        { name: _('Response received'),
          scope: :response_received },
        { name: _('Clarification needed'),
          scope: :clarification_needed },
        { name: _('Complete'),
          scope: :complete },
        { name: _('Other'),
          scope: :other }
        ]
    end

  end
end

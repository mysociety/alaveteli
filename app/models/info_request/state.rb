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
      [ { capital_label: _('Awaiting response'),
          label: _('awaiting response'),
          scope: :awaiting_response },
        { capital_label: _('Response received'),
          label: _('response received'),
          scope: :response_received },
        { capital_label: _('Clarification needed'),
          label: _('clarification needed'),
          scope: :clarification_needed },
        { capital_label: _('Complete'),
          label: _('complete'),
          scope: :complete },
        { capital_label: _('Other'),
          label: _('other'),
          scope: :other }
        ]
    end

  end
end

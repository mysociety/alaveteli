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

    def self.short_description(state)
      descriptions = {
            'waiting_classification'        => _("Awaiting classification"),
            'waiting_response'              => _("Awaiting response"),
            'waiting_response_overdue'      => _("Delayed"),
            'waiting_response_very_overdue' => _("Long overdue"),
            'not_held'                      => _("Information not held"),
            'rejected'                      => _("Refused"),
            'partially_successful'          => _("Partially successful"),
            'successful'                    => _("Successful"),
            'waiting_clarification'         => _("Waiting clarification"),
            'gone_postal'                   => _("Handled by post"),
            'internal_review'               => _("Awaiting internal review"),
            'error_message'                 => _("Delivery error"),
            'requires_admin'                => _("Unusual response"),
            'attention_requested'           => _("Reported"),
            'user_withdrawn'                => _("Withdrawn"),
            'vexatious'                     => _("Vexatious"),
            'not_foi'                       => _("Not an FOI request"),
          }
      if descriptions[state]
        descriptions[state]
      elsif InfoRequest.respond_to?(:theme_short_description)
        InfoRequest.theme_short_description(state)
      else
        raise _("unknown status {{state}}", :state => state)
      end
    end

    def self.phases
      [ { capital_label: _('Awaiting response'),
          label: _('awaiting response'),
          scope: :awaiting_response,
          param: 'awaiting-response' },
        { capital_label: _('Overdue'),
          label: _('overdue'),
          scope: :overdue,
          param: 'overdue' },
        { capital_label: _('Very overdue'),
          label: _('very overdue'),
          scope: :very_overdue,
          param: 'very-overdue' },
        { capital_label: _('Response received'),
          label: _('response received'),
          scope: :response_received,
          param: 'response-received' },
        { capital_label: _('Clarification needed'),
          label: _('clarification needed'),
          scope: :clarification_needed,
          param: 'clarification-needed' },
        { capital_label: _('Complete'),
          label: _('complete'),
          scope: :complete,
          param: 'complete' },
        { capital_label: _('Other'),
          label: _('other'),
          scope: :other,
          param: 'other' }
        ]
    end

    def self.phase_params
      Hash[phases.map{ |atts| [ atts[:scope], atts[:param] ]}]
    end
  end
end

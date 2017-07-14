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
            'waiting_classification'        => _("awaiting classification"),
            'waiting_response'              => _("awaiting response"),
            'waiting_response_overdue'      => _("delayed"),
            'waiting_response_very_overdue' => _("long overdue"),
            'not_held'                      => _("information not held"),
            'rejected'                      => _("refused"),
            'partially_successful'          => _("partially successful"),
            'successful'                    => _("successful"),
            'waiting_clarification'         => _("waiting clarification"),
            'gone_postal'                   => _("handled by post"),
            'internal_review'               => _("awaiting internal review"),
            'error_message'                 => _("delivery error"),
            'requires_admin'                => _("unusual response"),
            'attention_requested'           => _("reported"),
            'user_withdrawn'                => _("withdrawn"),
            'vexatious'                     => _("vexatious"),
            'not_foi'                       => _("not an FOI request"),
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
        { capital_label: _('Delayed'),
          label: _('overdue'),
          scope: :overdue,
          param: 'overdue' },
        { capital_label: _('Long overdue'),
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

    def self.phase_hash
      @phase_hash ||= Hash[phases.map{ |atts| [ atts[:scope], atts] }]
    end

  end
end

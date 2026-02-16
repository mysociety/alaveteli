# Helpers for rendering admin to-do list labels
module Admin::ToDoListHelper
  PRIORITY_IMPORTANT = %w[
    attention-messages
    embargoed-attention-messages
    attention-comments
    embargoed-attention-comments
    requires-admin
  ]

  PRIORITY_WARNING = %w[
    embargoed-requires-admin
    error-messages
    embargoed-error-messages
    holding-pen
  ]

  PRIORITY_INFO = %w[
    new-authorities
    update-authorities
  ]

  PRIORITY_NONE = %w[
    blank-contacts
    unclassified
  ]

  def todo_list_label_style(id)
    case id
    when *PRIORITY_NONE
      ''
    when *PRIORITY_INFO
      'label-info'
    when *PRIORITY_WARNING
      'label-warning'
    when *PRIORITY_IMPORTANT
      'label-important'
    else
      'label-important'
    end
  end
end

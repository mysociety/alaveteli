# Helpers for admin UI around replacing attachments
module Admin::FoiAttachments::ReplacementsHelper
  def clear_replacement_button(foi_attachment)
    title =
      if !foi_attachment.replaced?
        'No replacement to clear.'
      elsif !foi_attachment.retained?
        'Cannot clear replacements when the raw email has been erased.'
      else
        'Clear this replacement and revert to the original copy.'
      end

    tag.button(
      'Clear replacement',
      type: 'submit',
      class: 'btn btn-danger',
      name: '_method',
      value: 'delete',
      title: title,
      disabled: !foi_attachment.replacement_clearable?
    )
  end
end

##
# FormBuilder for refusal advice questions so they can be outputting differently
# based on the number of options each question has.
#
class RefusalAdviceQuestionForm < ActionView::Helpers::FormBuilder
  def wizard_option(option)
    @template.tag.div do
      value = option.value
      id = "#{@object.id}_#{value}"
      options = {
        id: id,
        class: 'wizard__question__option'
      }

      if refusal_advice_grid?(@object.options)
        input = @template.check_box_tag(object_name, value, false, options)
      else
        input = @template.radio_button_tag(object_name, value, false, options)
      end

      input + @template.label_tag(id, option.label)
    end
  end

  def wizard_options_class(options)
    if refusal_advice_grid?(options)
      'wizard__options--grid'
    else
      'wizard__options--list'
    end
  end

  private

  def refusal_advice_grid?(options)
    options.size > 2
  end
end

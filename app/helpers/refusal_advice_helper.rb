# Helpers for rendering help page refusal advice
module RefusalAdviceHelper
  def refusal_advice_question(question, option)
    tag.div do
      id = "#{question.id}_#{option.value}"

      if refusal_advice_grid?(question.options)
        input = check_box_tag(question.id, option.value, false, id: id)
      else
        input = radio_button_tag(question.id, option.value, false, id: id)
      end

      input + label_tag(id, option.label)
    end
  end

  def wizard_option_class(options)
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

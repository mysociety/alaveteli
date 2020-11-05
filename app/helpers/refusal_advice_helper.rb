# Helpers for rendering help page refusal advice
module RefusalAdviceHelper
  def refusal_advice_radio(question, option)
    tag.div do
      id = "#{ question.id }_#{ option.value }"

      radio_button_tag(question.id, option.value, false, id: id) +
        label_tag(id, option.label)
    end
  end

  def refusal_advice_checkbox(question, option)
    tag.div do
      id = "#{ question.id }_#{ option.value }"

      check_box_tag(question.id, option.value, false, id: id) +
        label_tag(id, option.label)
    end
  end
end

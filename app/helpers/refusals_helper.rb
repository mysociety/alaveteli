module RefusalsHelper
  def general_advice(data)
    build_questions(data[:general_advice])
  end

  def specific_advice(data, exemption:)
    # TODO: Render all exemptions unless we provide one
    build_questions(data[:specific_advice][exemption])
  end

  private

  def build_questions(data)
    data.map { |data| build_question(data) }.join.html_safe
  end

  def build_question(data)
    return build_questions(data) if data.is_a?(Array)

    tag.div(class: 'question') do
      concat tag.p(class: 'question__title') { data[:question] }
      concat tag.div(class: 'question__yes') { build_action(data[true]) }
      concat tag.div(class: 'question__no') { build_action(data[false]) }
    end
  end

  def build_action(data)
    return build_questions(data) if data.is_a?(Array)

    tag.div(class: 'question__action') do
      concat tag.div(class: 'question__render') { render data[:render] }
      concat tag.div(class: 'question__template-tags',
                     data: { tags: data[:followup_template_tags] })
    end
  end
end

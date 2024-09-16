# == Schema Information
# Schema version: 20240916160558
#
# Table name: project_insights
#
#  id              :bigint           not null, primary key
#  info_request_id :bigint
#  project_id      :bigint
#  output          :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Project::Insight < ApplicationRecord
  belongs_to :info_request
  belongs_to :project

  serialize :output, type: Hash, coder: JSON, default: {}

  def perform!
    update!(output: parser.parse(llm_response.chat_completion))
  end

  def queue
    WorkflowJob.perform_later(self)
  end

  private

  def text
    info_request.chunks.similarity_search(questions.first)[0].text
  end

  def questions
    project.key_set.keys.pluck(:title)
  end

  def llm_response
    LangchainrbRails.config.vectorsearch.llm.chat(
      messages: [
        { role: 'system', content: <<~TXT },
          You are an assistant who finds and extracts answers in Freedom of
          Information responses into a structured JSON data format.

          The responses may contains the questions asked as well as the
          responses. You should ignore the questions and only focus on the
          answers in the responses.

          Sometimes the questions may delve into more abstract aspects of the
          content, such as error messages or notes within the response that
          could provide valuable insights to a human analyzing the data.

          Restrict the data types to strings exclusively. Do not return
          number, boolean, array, hash, or other data types.
        TXT
        { role: 'user', content: prompt_text }
      ]
    )
  end

  def parser
    properties = questions.each_with_index.inject({}) do |hash, (question, idx)|
      next hash if question.blank?

      hash["question#{idx + 1}"] = { type: 'string', description: question }
      hash
    end

    schema = {
      type: "object",
      properties: properties,
      additionalProperties: false
    }

    @parser ||= Langchain::OutputParsers::StructuredOutputParser.
      from_json_schema(schema)
  end

  def prompt_text
    prompt = Langchain::Prompt::PromptTemplate.new(
      input_variables: %w[format_instructions],
      template: <<~TXT)
        Find answers to the following questions in the text provided, following
        the format instructions to structure the output accordingly.

        #{questions.map.with_index { |q, i| "Question #{i + 1}: #{q}" }.join("\n")}

        [START TEXT]
        #{text}
        [END TEXT]

        [START FORMAT INSTRUCTIONS]
        {format_instructions}
        If answer isn't provided in the text respond with an empty string.
        [END FORMAT INSTRUCTIONS]
      TXT

    prompt.format(format_instructions: parser.get_format_instructions)
  end
end

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

  def queue
    WorkflowJob.perform_later(self)
  end

  def perform!
    update!(output: make_output)
  end

  def make_output
    project.key_set.keys.limit(3).inject({}) do |hash, key|
      hash[key.id] = ask(key)
      hash
    end
  end

  def ask(key)
    question = key.title
    chunks = info_request.chunks.similarity_search(question, k: 4)
    contexts = chunks.map { ["ID: #{_1.id}", _1.as_vector].join("\n") }

    response = Response.new(question, contexts).to_h
    chunk = chunks.find(response[:id]) if response[:id]
    answer = response[:answer]

    {
      question: question,
      answer: answer,
      chunk_id: chunk&.id,
      info_request_id: chunk&.info_request_id,
      incoming_message_id: chunk&.incoming_message_id,
      foi_attachment_id: chunk&.foi_attachment_id
    }
  end

  class Response # :nodoc:
    attr_reader :question, :contexts

    def initialize(question, contexts)
      @question = question
      @contexts = contexts
    end

    def to_h
      parser.parse(llm_response.chat_completion)
    rescue
      {}
    end

    private

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
          { role: 'user', content: prompt }
        ]
      )
    end

    def schema
      {
        type: 'object',
        properties: {
          id: {
            type: 'number',
            description: 'The ID of the context where the answer is from'
          },
          answer: {
            type: 'string',
            description: "The answer to the question: #{question}"
          }
        },
        additionalProperties: false
      }
    end

    def parser
      Langchain::OutputParsers::StructuredOutputParser.from_json_schema(schema)
    end

    def prompt(question, contexts)
      template = Langchain::Prompt::PromptTemplate.new(
        input_variables: %w[format_instructions],
        template: <<~TXT)
          Find answers to the following question in the context provided,
          following the format instructions to structure the output accordingly.

          [START QUESTION]
          #{question}
          [END QUESTION]

          [START CONTEXT]
          #{contexts.join("\n---\n")}
          [END CONTEXT]

          [START FORMAT INSTRUCTIONS]
          {format_instructions}
          If answer isn't provided in the text respond with an empty string.
          [END FORMAT INSTRUCTIONS]
        TXT

      template.format(format_instructions: parser.get_format_instructions)
    end
  end
end

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
    llm: Langchain::LLM::Ollama.new(
      url: ENV.fetch('OLLAMA_URL', 'http://127.0.0.1:11434'),
      default_options: {
        temperature: 0.0,
        completion_model_name: 'mistral',
        embeddings_model_name: 'mistral',
        chat_completion_model_name: 'mistral'
      }
    )
  )
end

require 'net/http'

class Net::HTTP
  alias original_initialize initialize

  def initialize(*args)
    original_initialize(*args)
    self.read_timeout = 600
  end
end

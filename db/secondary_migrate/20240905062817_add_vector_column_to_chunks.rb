class AddVectorColumnToChunks < ActiveRecord::Migration[7.0]
  def change
    add_column :chunks, :embedding, :vector,
      limit: LangchainrbRails.config.vectorsearch.llm.default_dimensions
  end
end

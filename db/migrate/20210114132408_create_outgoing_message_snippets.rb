class CreateOutgoingMessageSnippets < ActiveRecord::Migration[5.2]
  def change
    # all fields are translatable
    create_table :outgoing_message_snippets, &:timestamps
  end
end

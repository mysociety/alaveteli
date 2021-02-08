##
# Predefined helpful text snippets which can added to outgoing messages
#
class OutgoingMessage::Snippet < ApplicationRecord
  include AdminColumn
  include Taggable

  @non_admin_columns = %w(name)

  translates :name, :body
  include Translatable # include after call to translates

  validates :name, :body, presence: true
end

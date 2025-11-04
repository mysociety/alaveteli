# == Schema Information
#
# Table name: outgoing_message_snippets
#
#  id                          :bigint           not null, primary key
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  outgoing_message_snippet_id :bigint           not null
#  name                        :string
#  body                        :text
#

##
# Predefined helpful text snippets which can added to outgoing messages
#
class OutgoingMessage::Snippet < ApplicationRecord
  include Taggable

  admin_columns exclude: %i[name]

  def self.admin_title
    'Snippet'
  end

  translates :name, :body
  include Translatable # include after call to translates

  validates :name, :body, presence: true
end

OutgoingMessage::Snippet::Translation.class_eval do
  with_options if: ->(t) { !t.default_locale? && t.required_attribute_submitted? } do |required|
    required.validates :name, :body, presence: true
  end

  def default_locale?
    AlaveteliLocalization.default_locale?(locale)
  end

  def required_attribute_submitted?
    OutgoingMessage::Snippet.translated_attribute_names.compact.any? do |attribute|
      !read_attribute(attribute).blank?
    end
  end
end

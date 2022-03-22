# == Schema Information
# Schema version: 20220210114052
#
# Table name: outgoing_message_snippets
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#  body       :text
#

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

OutgoingMessage::Snippet::Translation.class_eval do
  with_options if: lambda { |t| !t.default_locale? && t.required_attribute_submitted? } do |required|
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

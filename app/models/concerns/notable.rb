module Notable
  extend ActiveSupport::Concern

  included do
    has_many :concrete_notes,
             class_name: 'Note',
             as: :notable,
             inverse_of: :notable,
             dependent: :destroy
  end

  def all_notes
    concrete_notes.with_translations + tagged_notes.with_translations
  end

  def tagged_notes
    Note.where(notable_tag: notable_tags)
  end

  private

  def notable_tags
    tags.map(&:name_and_value)
  end
end

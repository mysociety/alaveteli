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
    notes = concrete_notes.with_translations
    return notes.to_a unless Taggable.models.include?(self.class)

    notes + tagged_notes.with_translations
  end

  def tagged_notes
    Note.where(notable_tag: notable_tags)
  end

  private

  def notable_tags
    tags.inject([]) do |arr, tag|
      arr << tag.name
      arr << tag.name_and_value if tag.value
      arr
    end
  end
end

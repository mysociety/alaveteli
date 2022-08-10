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
    concrete_notes.with_translations
  end
end

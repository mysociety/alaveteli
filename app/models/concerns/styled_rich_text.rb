module StyledRichText
  extend ActiveSupport::Concern

  COLOUR_STYLE_LABELS = {
    '🔴 Red': 'red',
    '🟡 Yellow': 'yellow',
    '🟢 Green': 'green',
    '🔵 Blue': 'blue'
  }.freeze

  included do
    translates :rich_body, touch: true
    delegate :rich_body, :rich_body=, :rich_body?, to: :translation
    after_save { translation.rich_body.save if translation.rich_body.changed? }

    translation_class.has_rich_text :rich_body
  end

  class_methods do
    def styles(labels, default:)
      cattr_accessor :style_labels, instance_accessor: false, default: labels

      enum :style, labels.values.index_by(&:itself),
                   default: default,
                   suffix: true
    end
  end
end

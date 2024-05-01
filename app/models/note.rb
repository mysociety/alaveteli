# == Schema Information
# Schema version: 20240227080436
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  style        :string           default("original"), not null
#  body         :text
#

class Note < ApplicationRecord
  include AdminColumn

  translates :body
  translates :rich_body, touch: true
  include Translatable
  delegate :rich_body, :rich_body=, :rich_body?, to: :translation
  after_save { rich_body.save if rich_body.changed? }

  cattr_accessor :default_style, default: 'original'
  cattr_accessor :style_labels, default: {
    '🔴 Red': 'red',
    '🟡 Yellow': 'yellow',
    '🟢 Green': 'green',
    '🔵 Blue': 'blue',
    'Original': 'original'
  }

  enum :style, Note.style_labels.values.index_by(&:itself),
               default: Note.default_style,
               suffix: true

  belongs_to :notable, polymorphic: true

  validates :body, presence: true, if: ->(n) { n.original_style? }
  validates :rich_body, presence: true, unless: ->(n) { n.original_style? }
  validates :style, presence: true
  validates :notable_or_notable_tag, presence: true

  def self.sort(notes)
    notes.sort_by! { Note.style_labels.values.index(_1.style) }
  end

  def to_plain_text
    b = original_style? ? ActionText::Fragment.wrap(body) : rich_body
    b.to_plain_text
  end

  private

  def notable_or_notable_tag
    notable || notable_tag
  end

  class Translation # :nodoc:
    has_rich_text :rich_body
  end
end

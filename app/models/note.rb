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
  include Translatable

  cattr_accessor :default_style, default: 'original'
  cattr_accessor :style_labels, default: {
    '🔵 Blue': 'blue',
    '🔴 Red': 'red',
    '🟢 Green': 'green',
    '🟡 Yellow': 'yellow',
    'Original': 'original'
  }

  enum :style, Note.style_labels.values.index_by(&:itself),
               default: Note.default_style,
               suffix: true

  belongs_to :notable, polymorphic: true

  validates :body, presence: true
  validates :style, presence: true
  validates :notable_or_notable_tag, presence: true

  def self.sort(notes)
    notes.sort_by! { Note.style_labels.values.index(_1.style) }
  end

  private

  def notable_or_notable_tag
    notable || notable_tag
  end
end

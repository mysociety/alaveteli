# == Schema Information
# Schema version: 20220720085105
#
# Table name: notes
#
#  id           :bigint           not null, primary key
#  notable_type :string
#  notable_id   :bigint
#  notable_tag  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  body         :text
#

class Note < ApplicationRecord
  include AdminColumn

  translates :body
  include Translatable

  belongs_to :notable, polymorphic: true

  validates :body, presence: true
  validates :notable, presence: true
end

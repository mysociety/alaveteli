# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer        not null, primary key
#  locale        :string
#  name          :text           not null
#

class PublicBodyHeading < ActiveRecord::Base
    has_and_belongs_to_many :public_body_categories
end

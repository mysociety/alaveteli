# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer        not null, primary key
#  name          :text           not null
#

class PublicBodyHeading < ActiveRecord::Base
    has_and_belongs_to_many :public_body_categories

    translates :name

    validates_uniqueness_of :name, :message => N_("Name is already taken")
end

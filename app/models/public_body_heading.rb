# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

class PublicBodyHeading < ActiveRecord::Base
    attr_accessible :locale, :name, :display_order, :translated_versions,
                    :translations_attributes

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_categories, :order => :category_display_order, :through => :public_body_category_links
    default_scope order('display_order ASC')

    translates :name

    validates_uniqueness_of :name, :message => 'Name is already taken'
    validates_presence_of :name, :message => 'Name can\'t be blank'
    validates :display_order, :numericality => { :only_integer => true,
                                                 :message => 'Display order must be a number' }

    before_validation :on => :create do
        unless self.display_order
            self.display_order = PublicBodyHeading.next_display_order
        end
    end

    include Translatable

    def add_category(category)
        unless public_body_categories.include?(category)
            public_body_categories << category
        end
    end

    def self.next_display_order
        if max = maximum(:display_order)
            max + 1
        else
            0
        end
    end
end

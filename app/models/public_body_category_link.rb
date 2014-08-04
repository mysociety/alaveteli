# == Schema Information
#
# Table name: public_body_category_link
#
#  public_body_category_id       :integer        not null
#  public_body_heading_id        :integer        not null
#  category_display_order        :integer
#

class PublicBodyCategoryLink < ActiveRecord::Base
    attr_accessible :public_body_category_id, :public_body_heading_id, :category_display_order

    belongs_to :public_body_category
    belongs_to :public_body_heading
end
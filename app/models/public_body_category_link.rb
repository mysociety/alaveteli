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
    validates :category_display_order, :numericality => { :only_integer => true,
                                                          :message => N_('Display order must be a number') }

    before_validation :on => :create do
        unless self.category_display_order
            self.category_display_order = PublicBodyCategoryLink.next_display_order(self.public_body_heading_id)
        end
    end

    def PublicBodyCategoryLink.next_display_order(heading_id)
        if last = where(:public_body_heading_id => heading_id).order(:category_display_order).last
            last.category_display_order + 1
        else
            0
        end
    end

end

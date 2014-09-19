FactoryGirl.define do
    factory :public_body_heading do

        factory :silly_heading do
            name 'Silly ministries'
            display_order 0
            after_create do |heading|
               FactoryGirl.create(:useless_link, :public_body_heading => heading,
                                                 :category_display_order => 0)
               FactoryGirl.create(:lonely_link, :public_body_heading => heading,
                                                 :category_display_order => 1)
            end
        end

        factory :popular_heading do
            name 'Popular agencies'
            display_order 1
            after_create do |heading|
               FactoryGirl.create(:popular_link, :public_body_heading => heading,
                                                 :category_display_order => 0)
            end
        end

        factory :heading_with_no_categories do
            name 'Heading with no categories'
            display_order 2
        end

    end
end

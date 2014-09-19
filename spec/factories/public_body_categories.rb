
FactoryGirl.define do
    factory :public_body_categories do

        factory :useless_category do
            title 'Useless ministries'
            category_tag 'useless_agency'
            description "a useless ministry"
        end

        factory :lonely_category do
            title 'Lonely agencies'
            category_tag 'lonely_agency'
            description "a lonely agency"
        end

        factory :popular_category do
            title 'Popular agencies'
            category_tag 'popular_agency'
            description "a popular agency"
        end
    end
end

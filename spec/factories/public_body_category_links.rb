FactoryGirl.define do
    factory :public_body_category_link do
        factory :useless_link do
             association :public_body_category, :factory => :useless_category
        end
        factory :lonely_link do
            association :public_body_category, :factory => :lonely_category
        end
        factory :popular_link do
            association :public_body_category, :factory => :popular_category
        end
    end
end

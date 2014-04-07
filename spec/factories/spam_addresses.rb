FactoryGirl.define do
    factory :spam_address do
        sequence(:email) { |n| "spam-#{ n }@example.org" }
    end
end

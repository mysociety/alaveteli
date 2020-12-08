FactoryBot.define do
  factory :legislation do
    key { 'foi' }
    short { 'FOI' }
    full { 'Freedom of Information' }

    initialize_with { new(key: key, short: short, full: full) }
  end
end

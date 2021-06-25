FactoryBot.define do
  factory :legislation do
    key { 'foi' }
    short { 'FOI' }
    full { 'Freedom of Information' }
    refusals { ['s 12'] }

    initialize_with do
      new(key: key, short: short, full: full, refusals: refusals)
    end
  end
end

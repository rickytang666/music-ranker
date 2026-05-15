FactoryBot.define do
  factory :ranking do
    user
    sequence(:name) { |n| "Ranking #{n}" }
  end
end

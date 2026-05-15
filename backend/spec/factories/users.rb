FactoryBot.define do
  factory :user do
    sequence(:spotify_id) { |n| "spotify_user_#{n}" }
    display_name { "Test User" }
  end
end

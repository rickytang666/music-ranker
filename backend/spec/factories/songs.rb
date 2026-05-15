FactoryBot.define do
  factory :song do
    sequence(:spotify_track_id) { |n| "track_#{n}" }
    sequence(:title) { |n| "Song #{n}" }
    artist_name { "Artist" }
  end
end

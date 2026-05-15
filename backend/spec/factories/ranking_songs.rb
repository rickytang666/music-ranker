FactoryBot.define do
  factory :ranking_song do
    ranking
    song
    elo_score { 1000.0 }
    matchup_count { 0 }
  end
end

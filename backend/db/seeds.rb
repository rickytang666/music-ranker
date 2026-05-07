user = User.find_or_create_by!(spotify_id: "mock_user_001") do |u|
  u.display_name = "dev user"
  u.access_token = "mock_access_token"
  u.refresh_token = "mock_refresh_token"
  u.token_expires_at = 1.hour.from_now
end

ranking = Ranking.find_or_create_by!(user: user, name: "drake discography")

tracks = [
  { spotify_track_id: "mock_001", title: "God's Plan",        artist_name: "Drake", album_name: "Scorpion" },
  { spotify_track_id: "mock_002", title: "HYFR",              artist_name: "Drake", album_name: "Take Care" },
  { spotify_track_id: "mock_003", title: "Marvins Room",      artist_name: "Drake", album_name: "Take Care" },
  { spotify_track_id: "mock_004", title: "Hold On, We're Going Home", artist_name: "Drake", album_name: "Nothing Was The Same" },
  { spotify_track_id: "mock_005", title: "Passionfruit",      artist_name: "Drake", album_name: "More Life" },
  { spotify_track_id: "mock_006", title: "From Time",         artist_name: "Drake", album_name: "Nothing Was The Same" },
]

songs = tracks.map { |t| Song.find_or_create_by!(spotify_track_id: t[:spotify_track_id]) { |s| s.assign_attributes(t) } }

songs.each do |song|
  RankingSong.find_or_create_by!(ranking: ranking, song: song)
end

# a few mock matchups
[
  [ songs[0], songs[1], songs[0] ],
  [ songs[2], songs[3], songs[3] ],
  [ songs[4], songs[5], songs[4] ],
  [ songs[0], songs[3], songs[3] ],
  [ songs[1], songs[4], songs[4] ],
].each do |song_a, song_b, winner|
  Matchup.find_or_create_by!(
    ranking: ranking,
    song_a: song_a,
    song_b: song_b
  ) do |m|
    m.winner = winner
    m.played_at = Time.current
  end
end

puts "seeded: 1 user, 1 ranking, #{songs.count} songs, #{ranking.matchups.count} matchups"

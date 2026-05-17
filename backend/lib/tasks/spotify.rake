namespace :spotify do
  desc "backfill spotify_album_id for songs that are missing it"
  task backfill_album_ids: :environment do
    songs = Song.where(spotify_album_id: nil)
    total = songs.count

    if total.zero?
      puts "all songs already have spotify_album_id"
      next
    end

    user = User.first
    abort "no users found — need a spotify-authenticated user" unless user

    client = SpotifyClient.new(user)

    # one api call per unique album (grouped by name + art url)
    groups = songs.group_by { |s| [s.album_name, s.album_art_url] }
    puts "#{total} songs across #{groups.size} unique albums"

    updated = 0
    errors  = 0

    groups.each do |(album_name, _), group_songs|
      representative = group_songs.first
      begin
        data = client.track(representative.spotify_track_id)
        album_id = data.dig("album", "id")

        if album_id
          ids = group_songs.map(&:id)
          Song.where(id: ids).update_all(spotify_album_id: album_id)
          updated += ids.size
          print "."
        else
          warn "\nskipped '#{album_name}' — no album id in response"
          errors += group_songs.size
        end
      rescue => e
        warn "\nfailed '#{album_name}': #{e.message}"
        errors += group_songs.size
      end

      $stdout.flush
      sleep 0.05 # stay under rate limit
    end

    puts "\ndone — #{updated}/#{total} updated, #{errors} errors"
  end
end

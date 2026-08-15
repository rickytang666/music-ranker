class SpotifySyncService
  def self.call
    new.call
  end

  def call
    rankings = Ranking
      .includes(:user, :ranking_songs)
      .where.not(spotify_sync_count: nil)
      .where(spotify_sync_error: false)

    stats = { total: rankings.count, ok: 0, skipped: 0, paused: 0, failed: 0 }
    Rails.logger.info "spotify sync started: #{stats[:total]} rankings"

    rankings.find_each { |ranking| stats[sync(ranking)] += 1 }

    Rails.logger.info "spotify sync finished: " \
      "ok=#{stats[:ok]} skipped=#{stats[:skipped]} paused=#{stats[:paused]} " \
      "failed=#{stats[:failed]} of #{stats[:total]}"
    stats
  end

  private

  # each branch returns its stats key so the run gets a countable summary
  def sync(ranking)
    if ranking.ranking_songs.empty?
      Rails.logger.info "spotify sync skipped ranking #{ranking.id}: no songs"
      return :skipped
    end

    SpotifyExportService.call(
      ranking.user,
      ranking,
      name: ranking.name,
      count: ranking.spotify_sync_count
    )
    Rails.logger.info "spotify sync ok ranking #{ranking.id}"
    :ok
  rescue SpotifyClient::ForbiddenError => e
    ranking.update_column(:spotify_sync_error, true)
    Rails.logger.warn "spotify sync paused ranking #{ranking.id}: #{e.message}"
    :paused
  rescue => e
    Rails.logger.error "spotify sync failed ranking #{ranking.id}: #{e.class}: #{e.message}"
    :failed
  end
end

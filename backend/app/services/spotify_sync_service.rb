class SpotifySyncService
  def self.call
    new.call
  end

  def call
    rankings = Ranking
      .includes(:user, :ranking_songs)
      .where.not(spotify_sync_count: nil)
      .where(spotify_sync_error: false)

    rankings.find_each { |ranking| sync(ranking) }
  end

  private

  def sync(ranking)
    if ranking.ranking_songs.empty?
      Rails.logger.info "spotify sync skipped ranking #{ranking.id}: no songs"
      return
    end

    SpotifyExportService.call(
      ranking.user,
      ranking,
      name: ranking.name,
      count: ranking.spotify_sync_count
    )
    Rails.logger.info "spotify sync ok ranking #{ranking.id}"
  rescue SpotifyClient::ForbiddenError => e
    ranking.update_column(:spotify_sync_error, true)
    Rails.logger.warn "spotify sync paused ranking #{ranking.id}: #{e.message}"
  rescue => e
    Rails.logger.error "spotify sync failed ranking #{ranking.id}: #{e.message}"
  end
end
